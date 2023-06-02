// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@aa/contracts/core/BasePaymaster.sol";
import "@usernames/security/Guard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@usernames/library/Errors.sol";
import "@usernames/library/Helpers.sol";

contract UsernamesPaymaster is BasePaymaster, Guard {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using Helpers for *;

    mapping(address => uint256) public senderNonce;

    constructor(IEntryPoint _entryPoint, address owner) BasePaymaster(_entryPoint) Ownable(owner) {}

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
                    validAfter
                )
            );
    }

    /**
     * @notice gets the actual number of signatures passed with the userOp in paymasterInput
     * @param signatures an array of signature
     * @dev 0 means we don't know the length of the signature.
     * i.e you should always explicitly check for the length if this method returns 0
     */
    function getNumOfSignatures(bytes calldata signatures) public pure returns (uint256) {
        // explicitly check for length if value is not 1
        return signatures.length == 64 || signatures.length == 65 ? 1 : 0;
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);
        return ("", 0xa11ce);
    }
}
