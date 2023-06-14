// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@usernames/Paymaster.sol";
import {ERC20Test} from "@usernames/tokens/ERC20.sol";
import {TestContract} from "mocks/MocksAndContracts.sol";

uint constant privateKey = 0xa11ce;

contract UsernamesPaymasterHarness is UsernamesPaymaster {
    constructor(
        address sender,
        address feed
    ) UsernamesPaymaster(IEntryPoint(sender), ENS(sender), feed) {}

    function exposed__validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    ) external returns (bytes memory context, uint256 validationData) {
        return _validatePaymasterUserOp(userOp, userOpHash, requiredPreFund);
    }

    function exposed__postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external {
        _postOp(mode, context, actualGasCost);
    }

    function exposed__pack(UserOperation calldata userOp) external pure returns (bytes memory ret) {
        return _pack(userOp);
    }

    function decodeContext(
        bytes calldata context
    ) external pure returns (address, address, bytes32, uint256) {
        address account = address(bytes20(context[:20]));
        address feeToken = address(bytes20(context[20:40]));
        bytes32 nodeHash = bytes32(context[104:]);
        uint256 requiredPreFund = uint256(bytes32(context[72:104]));
        return (account, feeToken, nodeHash, requiredPreFund);
    }
}

contract PaymasterTest is Test {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;

    UserOperation ops;

    address tester = vm.addr(privateKey);

    UsernamesPaymasterHarness paymaster;
    TestContract public tc;
    ERC20Test public testToken;
    bytes32 testNode = keccak256(abi.encodePacked(bytes32(0), keccak256("test")));

    function owner(bytes32 node) external view returns (address) {
        (node);
        return tester;
    }

    function changeSigners(address signer1, address signer2, uint8 sigCount) public {
        vm.startPrank(tester);
        paymaster.setNodeSigners(signer1, signer2, testNode, sigCount);
        vm.stopPrank();
    }

    function setUp() public {
        tc = new TestContract();
        testToken = new ERC20Test();
        paymaster = new UsernamesPaymasterHarness(address(this), address(tc));
        deal(address(this), 2e18);
        paymaster.fundNode{value: 1e18}(testNode);
        paymaster.addToken(testToken, "bit_usdc");
        changeSigners(tester, tester, uint8(SigCount.ZERO));
        setOp();
    }

    function setOp() internal {
        vm.startPrank(tester);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, testNode.toEthSignedMessageHash());
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        ops = UserOperation({
            sender: tester,
            nonce: vm.getNonce(tester),
            initCode: new bytes(0),
            callData: new bytes(0),
            callGasLimit: uint256(0),
            verificationGasLimit: 4e4,
            preVerificationGas: uint256(0),
            maxFeePerGas: 3.5e4,
            maxPriorityFeePerGas: 3.5e4,
            paymasterAndData: abi.encodePacked(
                paymaster,
                abi.encode(uint48(block.timestamp + 86400), uint48(block.timestamp)),
                testNode,
                address(testToken),
                abi.encodePacked(signature, signature)
            ),
            signature: signature
        });
    }

    // ######## // ######## // _validatePaymasterUserOp

    function testRevertsOnInvalidSignatureLength() external {}

    function testRevertsIfRequiredPrefundIsLow() external {}

    function testRevertsIfConfigsNotSet() external {}

    function testRevertsIfVerificationGasLimitISLessThanPostOp() external {}

    function testRevertsWithIncorrectPaymasterAndData() external {}

    function testRevertsIfTokenPairDoesNotExist() external {}

    function testDebtIsCachedForInitialOperation() external {}

    function testDebtMustBePaidForSecondOperation() external {}

    function testCannotUseNodeHashOtherThanSelf() external {}

    function testZeroSigCountPassesWithOrWithoutSigLength() external {}

    function testOneSigCountPassesOnValidSignature() external {}

    function testOneSigCountFailsForAnInvalidSignature() external {}

    function testTwoSigCountPassesOnValidSignature() external {}

    function testTwoSigCountFailsForAnInvalidSignature() external {}

    function testPaymasterAndDataIsProperlyDecoded() external {
        bytes32 userOpHash = keccak256(paymaster.exposed__pack(ops));
        uint256 _requiredPreFund = 21000;

        (bytes memory context, ) = paymaster.exposed__validatePaymasterUserOp(
            ops,
            userOpHash,
            _requiredPreFund
        );
        (address account, address feeToken, bytes32 nodeHash, uint256 requiredPreFund) = paymaster
            .decodeContext(context);

        assertEq(account, tester);
        assertEq(feeToken, address(testToken));
        assertEq(nodeHash, testNode);
        assertEq(requiredPreFund, _requiredPreFund);
    }

    // ######## // ######## // _postOp

    function testDebtIsCachedOnRevertMode() external {}

    function testNodeGetsChargedForRevertedPostOp() external {}

    function testTokenIsTransferredOnNormalMode() external {}

    function testNodeIsDebitedOnPostOp() external {}

    function testCorrectPriceIsFetchedFromOracle() external {}
}
