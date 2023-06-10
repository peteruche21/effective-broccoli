// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@aa/contracts/core/BasePaymaster.sol";
import "@usernames/security/Guard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@usernames/library/Errors.sol";
import "@usernames/library/Helpers.sol";
import "@usernames/utils/OracleConsumer.sol";
import "@usernames/registrars/FIFSRegistrar.sol";

// NOTE: the `_validatePaymasterUserOp` and `_postOp` can be gamed, so please do not use this in production
// for ease of testing (reduced validation steps, only this storage access, cheaper userOp validation)
// userOp payment logic is completely moved to the postOp
// this makes the paymaster to pay at least one gas free transaction, even if the userOp sender
// is not registering a domain
// you should avoid setting SigCount to ZERO

/// @title Global Paymaster Registrar
/// @author Peter Anyaogu
/// @notice ENS Registrar that registers subdomains for users and also uses name hashes for gas sponsorship
/// NameHashes: It uses nodes to represent a user's share of the contract balance
/// all addresses that have a subdomain to a node, can consume the nodes balance for an EIP4337 transaction
/// A valid signer can sign transaction, but its not strictly required, however, the node config must be set
/// @dev dual mode paymasters that doubles as:
/// 1: a verifying paymaster with support of 0 to 2FA signature validation
/// 2: an ERC20 paymaster where the user pays with a supported token
/// 3: a global paymaster where anyone can pay gas fees for users
contract UsernamesPaymaster is FIFSRegistrar, BasePaymaster, Guard {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using PriceFeedConsumer for mapping(IERC20 => address);
    using Helpers for *;

    // estimated cost of executing the post_operation
    uint256 public constant COST_OF_POST = 40000;
    // used to calculate the amount that will be placed as fine for reverted transactions
    uint256 public constant REVERT_FINE_CONSTANT = .1e24;

    address public ethPriceFeed;

    mapping(bytes32 => uint256) nodeToBalance;
    mapping(address => uint256) public senderNonce;
    mapping(IERC20 => address) tokenToPriceFeed;
    mapping(bytes32 => SigConfig) nodeToConfig;

    mapping(address => mapping(bytes32 => Debt)) public debt;

    modifier isAuthorized(bytes32 node) {
        if (ens.owner(node) != msg.sender) revert UnAuthorized();
        _;
    }

    constructor(
        IEntryPoint _entryPoint,
        ENS ensAddr,
        address _ethPriceFeed,
        address _owner
    ) BasePaymaster(_entryPoint) Ownable(_owner) {
        ens = ensAddr;
        ethPriceFeed = _ethPriceFeed;
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        // lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata pnd = userOp.paymasterAndData;
        // copy directly the userOp from calldata up to (but not including) the paymasterAndData.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(pnd.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    /**
     * return the hash we're going to sign off-chain (and validate on-chain)
     * this method is called by the off-chain service, to sign the request.
     * it is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * note that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     */
    function getHash(
        UserOperation calldata userOp,
        bytes32 nodeHash,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.
        return
            keccak256(
                abi.encode(
                    pack(userOp),
                    block.chainid,
                    address(this),
                    senderNonce[userOp.getSender()],
                    validUntil,
                    validAfter,
                    nodeHash
                )
            );
    }

    ///
    /// @param primarySigner - The primary/main signer
    /// @param secondarySigner  - an additional signer that can be use for 2FA or delegation
    /// @param sigCount - total number of signatures required in the validation step
    /// @param node - the domain name the transaction sender has.
    function setNodeSigners(
        address primarySigner,
        address secondarySigner,
        bytes32 node,
        uint8 sigCount
    ) external isAuthorized(node) {
        if (sigCount > 2) revert InvalidConfig();
        nodeToConfig[node].verifyingSigner1 = primarySigner;
        nodeToConfig[node].verifyingSigner2 = secondarySigner;
        nodeToConfig[node].validNumOfSignatures = SigCount(sigCount);
    }

    ///
    /// @param token An ERC20 Token, will be used for gas payment
    /// @param priceFeed the corresponding priceFeed for that token
    /// @dev only tokens with priceFeeds can be set. (stable and non stable);
    function addToken(IERC20 token, address priceFeed) external onlyOwner {
        require(tokenToPriceFeed[token] == address(0), "Token already set");
        tokenToPriceFeed[token] = priceFeed;
    }

    function fundNode(bytes32 node) external payable {
        nodeToBalance[node] += msg.value;
    }

    /// @dev only a node owner can withdraw balances specific tot he node.
    function withdraw(bytes32 node) external isAuthorized(node) {
        uint256 balance = nodeToBalance[node];
        nodeToBalance[node] = 0;
        payable(msg.sender).transfer(balance);
    }

    /**
     * paymasterAndData[:20] : address(this)
     * paymasterAndData[20:84] : abi.encode(validUntil, validAfter)
     * paymasterAndData[84:116] : bytes32(nodeHash)
     * paymasterAndData[116:116+20] : IERC20(feeToken)
     * paymasterAndData[116+20:] : signatures
     */
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
        if (userOp.paymasterAndData.length - 20 < 116 || userOp.verificationGasLimit < COST_OF_POST)
            revert FailedToValidatedOp();

        // Gets the node from the paymasterAndData
        // the node is hash of the TLD of userOp.sender
        // e.g `alice.usernames.bit` node is nameHash("usernames.bit")
        // determining if a subdomain exists for a caller is done off-chain by the signer
        bytes32 nodeHash = bytes32(userOp.paymasterAndData[84:116]);

        // when postOp is reverted, or during subdomain registration, the gasCost is cached as debt
        // and must be paid in the next validation step (userOp sponsorship)
        // no oracle conversion is done, no volatility is considered
        Debt memory _debt = debt[userOp.sender][nodeHash];
        if (requiredPreFund < _debt.amount) revert NotEnoughValueForGas();

        SigConfig memory nodeConfig = nodeToConfig[nodeHash];
        // if expectedValidationStep is ZERO, then the initial userOp sponsorship cannot be
        // guaranteed to be an ENS domain name registration
        SigCount expectedValidationStep = nodeConfig.validNumOfSignatures;

        (uint48 validUntil, uint48 validAfter) = abi.decode(
            userOp.paymasterAndData[20:84],
            (uint48, uint48)
        );

        // fetches the token the user wants to use in paying gas fee
        IERC20 feeToken = IERC20(address(bytes20(userOp.paymasterAndData[116:136])));
        // if there is no price oracle associated with the token, it is reverted
        if (tokenToPriceFeed[feeToken] == address(0)) revert FailedToValidatedOp();
        // the signatures can either be of length 64 || 65
        bytes calldata signatures = userOp.paymasterAndData[116 + 20:];
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            getHash(userOp, nodeHash, validUntil, validAfter)
        );

        // assume that the validation should pass
        validationData = _packValidationData(false, validUntil, validAfter);
        // set the postOp calldata in the context
        context = abi.encodePacked(
            userOp.sender,
            feeToken,
            userOp.gasPrice(),
            requiredPreFund,
            nodeHash
        );

        if (expectedValidationStep == SigCount.ONE) {
            // allows either the primary signer or secondary signer to validate paymasterAndData
            // assuming 1FA signature validation is used
            if (nodeConfig.verifyingSigner1 == address(0)) revert FailedToValidatedOp();
            address signer = _validateOneSignature(signatures, userOp.sender, hash);
            // if signature verification fails, return SIG_VALIDATION_FAILED but do not revert
            if (signer != nodeConfig.verifyingSigner1 || signer != nodeConfig.verifyingSigner2)
                validationData = _packValidationData(true, validUntil, validAfter);
        } else if (expectedValidationStep == SigCount.TWO) {
            // when 2FA is enabled, the 2 signatures must be represented in any order
            // but must correspond to the signers.
            // also, return SIG_VALIDATION_FAILED and do not revert, if sig validation fails
            if (
                nodeConfig.verifyingSigner1 == address(0) ||
                nodeConfig.verifyingSigner2 == address(0)
            ) revert FailedToValidatedOp();
            (address primarySigner, address secondarySigner) = _validateTwoSignatures(
                signatures,
                userOp.sender,
                hash
            );
            if (
                (primarySigner != nodeConfig.verifyingSigner1 &&
                    secondarySigner != nodeConfig.verifyingSigner2) ||
                (secondarySigner != nodeConfig.verifyingSigner1 &&
                    primarySigner != nodeConfig.verifyingSigner2)
            ) validationData = _packValidationData(true, validUntil, validAfter);
        }

        // debit the cached debt before paying for another one
        // reverts if unable to debit the cached debt
        // no token volatility is considered from when debt was cached
        if (_debt.amount > 0) {
            delete debt[userOp.sender][nodeHash];
            _payDebt(userOp.sender, nodeHash);
        }
    }

    ///
    /// @param _signature the signature in paymasterAndData
    /// @param caller userOp.sender
    /// @param _hash eth_signed_message hash
    function _validateOneSignature(
        bytes calldata _signature,
        address caller,
        bytes32 _hash
    ) internal returns (address signer) {
        if (_signature.total() != 1) revert InvalidSignatureLength();
        senderNonce[caller]++;
        signer = ECDSA.recover(_hash, _signature);
    }

    ///
    /// @param _signatures the signature in paymasterAndData
    /// @param caller userOp.sender
    /// @param _hash eth_signed_message hash
    /// @return signer1 == primarySigner
    /// @return signer2 == secondarySigner
    function _validateTwoSignatures(
        bytes calldata _signatures,
        address caller,
        bytes32 _hash
    ) internal returns (address signer1, address signer2) {
        if (_signatures.total() == 2) revert InvalidSignatureLength();
        (bytes memory signature1, bytes memory signature2) = _signatures.extractECDSASignatures();
        senderNonce[caller]++;
        signer1 = ECDSA.recover(_hash, signature1);
        signer2 = ECDSA.recover(_hash, signature2);
    }

    /// @notice the post operation does not guarantee that the debt will ever be cleared.
    /// while its not possible to process another userOp with an existing debt
    /// it does not stop bad actors from using this paymaster to execute expensive contract calls
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal virtual override {
        (
            address account,
            IERC20 feeToken,
            uint256 gasPrice,
            uint256 requiredPreFund,
            bytes32 nodeHash
        ) = abi.decode(context, (address, IERC20, uint256, uint256, bytes32));

        // calculate a token equivalent of the pre-calculated expenses
        int256 tokenCost = _getPriceFromOracle(feeToken, requiredPreFund);
        // calculate the real cost of the operation
        uint256 realCost = ((actualGasCost + COST_OF_POST * gasPrice) * uint256(tokenCost)) /
            requiredPreFund;

        if (mode == PostOpMode.postOpReverted) {
            // if popstOp reverted, deduct a fine from the node balance for signing a to-be-reverted post-operation
            nodeToBalance[nodeHash] -= (realCost * REVERT_FINE_CONSTANT) / 1e24;
            // cache the supposed amount as debt to be consumed in the next operation
            debt[account][nodeHash] = Debt(
                realCost,
                nodeToConfig[nodeHash].verifyingSigner1,
                feeToken
            );
            return;
        } else {
            // try to charge a user the cost of the transaction
            account.handleTokenTransfer(
                nodeToConfig[nodeHash].verifyingSigner1,
                realCost,
                feeToken
            );
        }

        nodeToBalance[nodeHash] -= realCost;
    }

    ///
    /// @param token ERC20 token to check price
    /// @param amount amount to convert after checking price
    function _getPriceFromOracle(
        IERC20 token,
        uint256 amount
    ) internal view returns (int256 _price) {
        _price = tokenToPriceFeed.getDerivedPrice(token, ethPriceFeed, int256(amount));
    }

    /// @notice pay the debt to the node owner
    function _payDebt(address debtor, bytes32 node) internal {
        debtor.handleTokenTransfer(
            debt[debtor][node].debtee,
            debt[debtor][node].amount,
            debt[debtor][node].token
        );
    }
}
