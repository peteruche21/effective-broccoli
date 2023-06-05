// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Helpers} from "@usernames/library/Helpers.sol";
import {TestContract} from "mocks/MocksAndContracts.t.sol";
import {ERC20Test, IERC20} from "@usernames/tokens/ERC20.sol";

contract HelperLibTest is Test {
    using Helpers for *;
    using ECDSA for bytes32;

    bytes32[] siblings;

    TestContract public tc;
    ERC20Test public testToken;

    uint256 testerPrivateKey = 0xA11ce;
    address tester = vm.addr(testerPrivateKey);
    bytes32 namehash = keccak256("alice.eth");

    function setUp() public {
        tc = new TestContract();
        testToken = new ERC20Test();
    }

    function testStrCompare() public {
        bytes memory a = "0xa";
        bytes memory b = bytes("0xa");
        bytes memory c = "0xb";
        assertEq(b.strCompare(a), true);
        assertEq(a.strCompare(c), false);
    }

    function testExternalStaticcallWithoutArgs() public {
        bytes memory payload = abi.encodeWithSelector(tc.returnUintFromStorage.selector);
        uint256 retData = payload.externalStaticcall(address(tc));
        assertEq(retData, 21);
    }

    function testExternalStaticcallWithArgs() public {
        bytes memory payload = abi.encodeWithSignature("returnUintFromArgs(uint256)", 5);
        uint256 retData = payload.externalStaticcall(address(tc));
        assertEq(retData, 5);
    }

    function testExternalStaticcallRevertsWithMessage() public {
        bytes memory payload = abi.encodeWithSelector(tc.revertWithMessage.selector);
        vm.expectCall(address(tc), payload);
        vm.expectRevert("external staticcall failed");
        payload.externalStaticcall(address(tc));
    }

    function testExternalCallWithoutReturn() public {
        bytes memory payload = abi.encodeWithSelector(tc.returnNothing.selector);
        vm.expectCall(address(tc), payload);
        payload.externalCall(address(tc));
        uint256 newNumber = tc.returnUintFromStorage();
        assertEq(newNumber, 31);
    }

    function testExternalCallWithReturn() public {
        bytes memory payload = abi.encodeWithSelector(tc.returnSomething.selector);
        vm.expectCall(address(tc), payload);
        uint256 retData = abi.decode(payload.externalCall(address(tc)), (uint256));
        assertEq(retData, 11);
        bytes memory payload2 = abi.encodeWithSelector(tc.returnCaller.selector);
        vm.expectCall(address(tc), payload2);
        address caller = abi.decode(payload2.externalCall(address(tc)), (address));
        assertTrue(caller == address(this));
    }

    function testExternalCallRevertsWithMessage() public {
        bytes memory payload = abi.encodeWithSelector(tc.revertWithMessage.selector);
        vm.expectCall(address(tc), payload);
        vm.expectRevert("external call failed");
        payload.externalCall(address(tc));
    }

    function testDelegateCallFromMsgSender() public {
        bytes memory payload = abi.encodeWithSelector(tc.returnCaller.selector);
        vm.expectCall(address(tc), payload);
        bytes memory ret = payload.externalDelegateCall(address(tc));
        address caller = abi.decode(ret, (address));
        assertTrue(caller == msg.sender);
    }

    function externalDelegatecallRevertsWithMessage() public {
        bytes memory payload = abi.encodeWithSelector(tc.revertWithMessage.selector);
        vm.expectCall(address(tc), payload);
        vm.expectRevert("external delegatecall failed");
        payload.externalDelegateCall(address(tc));
    }

    function testCheckAllowance() public {
        address self = address(this);
        uint256 allowance = self.checkAllowance(testToken);
        assertEq(allowance, 0);

        testToken.approve(self, 2e18);
        uint256 newAllowance = self.checkAllowance(testToken);
        assertEq(newAllowance, 2e18);
    }

    function testHandleTokenTransfer() public {
        address rand = address(0xabc);
        address self = address(this);

        testToken.approve(self, 2e18);
        uint256 newAllowance = self.checkAllowance(testToken);
        assertEq(newAllowance, 2e18);

        testToken.mint(self, 2e18);
        uint256 myBalance = testToken.balanceOf(self);
        assertEq(myBalance, 2e18);

        self.handleTokenTransfer(rand, 2e18, testToken);
        uint256 myNewBalance = testToken.balanceOf(self);
        assertEq(myNewBalance, 0);

        uint256 randBalance = testToken.balanceOf(rand);
        assertEq(randBalance, 2e18);
    }

    function testUseDelegate() public {
        siblings = [keccak256("0"), keccak256("1"), keccak256("2")];
        bool correctSibling1 = siblings.useDelegate(keccak256("0"));
        assertTrue(correctSibling1);
        bool correctSibling2 = siblings.useDelegate(keccak256("1"));
        assertTrue(correctSibling2);
        bool correctSibling3 = siblings.useDelegate(keccak256("2"));
        assertTrue(correctSibling3);
        bool wrongSibling = siblings.useDelegate(keccak256("5"));
        assertFalse(wrongSibling);
    }

    function testPreviewDelegation() public {
        siblings = [keccak256("uche.bit"), keccak256("kenzy.umuasa"), keccak256("ckas.umunwa")];

        bool validDelegate1 = siblings.previewDelegation(keccak256("uche.bit"));
        assertTrue(validDelegate1);
        bool validDelegate2 = siblings.previewDelegation(keccak256("kenzy.umuasa"));
        assertTrue(validDelegate2);
        bool validDelegate3 = siblings.previewDelegation(keccak256("ckas.umunwa"));
        assertTrue(validDelegate3);
        bool invalidDelegate2 = siblings.previewDelegation(namehash);
        assertFalse(invalidDelegate2);
    }

    function testValidECDSASignature() public {
        bytes32 hash = keccak256("Signed by Alice").toEthSignedMessageHash();
        vm.startPrank(tester);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(testerPrivateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        bytes memory sig = signature.extractECDSASignature();
        address signer = hash.recover(sig);
        assertEq(signer, tester);
    }

    function testValidECDSASignatures() public {
        bytes32 hash1 = keccak256("Signed by Alice").toEthSignedMessageHash();
        bytes32 hash2 = keccak256("Signed by Bob").toEthSignedMessageHash();
        vm.startPrank(tester);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(testerPrivateKey, hash1);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(testerPrivateKey, hash2);
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);
        vm.stopPrank();
        bytes memory signatures = abi.encodePacked(signature1, signature2);
        (bytes memory sig1, bytes memory sig2) = signatures.extractECDSASignatures();
        address signer1 = hash1.recover(sig1);
        address signer2 = hash2.recover(sig2);
        assertEq(signer1, tester);
        assertEq(signer2, tester);
        assertEq(signer1, signer2);
    }
}
