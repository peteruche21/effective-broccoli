// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

enum SigCount {
    ZERO,
    ONE,
    TWO
}

struct SigConfig {
    address verifyingSigner1;
    address verifyingSigner2;
    SigCount validNumOfSignatures;
}

struct Debt {
    uint256 amount;
    address debtee;
    IERC20 token;
}

library Helpers {
    /**
     * compares two strings
     * @param a - string A
     * @param b - String B
     */
    function strCompare(bytes memory a, bytes memory b) public pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    /// @notice function for making the actual external call
    /// @dev returns the value as-is without comparison
    /// @param _payload - the the encoded function signature in bytes
    /// @param _to - the contract address to send external call.
    /// @return - (uint256)
    function externalStaticcall(
        bytes calldata _payload,
        address _to
    ) public view returns (uint256) {
        (bool success, bytes memory returnData) = _to.staticcall(_payload);
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        revert("external staticcall failed");
    }

    /// @notice function for making the actual external call
    /// @dev returns the value as-is, handle the return value decoding in the calling method
    /// @param _payload - the the encoded function signature in bytes
    /// @param _to - the contract address to send external call.
    /// @return - (bytes)
    function externalCall(bytes calldata _payload, address _to) public returns (bytes memory) {
        (bool success, bytes memory returnData) = _to.call(_payload);
        if (success) {
            return returnData;
        }
        revert("external call failed");
    }

    /// @notice function for making the actual delegatecall
    /// @dev returns the value as-is, handle the return value decoding in the calling method
    /// @param _payload - the the encoded function signature in bytes
    /// @param _to - the contract address to delegate call to.
    /// @return - (bytes)
    function externalDelegateCall(
        bytes calldata _payload,
        address _to
    ) public returns (bytes memory) {
        (bool success, bytes memory returnData) = _to.delegatecall(_payload);
        if (success) {
            return returnData;
        }
        revert("external delegatecall failed");
    }

    /// @dev - internal function that handles transfer of ERC20 tokens
    /// @param from - the address of the transaction sender
    /// @param to - (optional) the address of fee receiver or VA
    /// @param amount - amount of tokens to be transferred to fee Receiver
    /// @param token - contract address of the ERC20 token
    function handleTokenTransfer(address from, address to, uint256 amount, IERC20 token) public {
        SafeERC20.safeTransferFrom(token, from, to, amount);
    }

    /// @dev - internal function that checks for token allowance
    /// @param txFrom - the address of the transaction sender
    /// @param token - contract address of the ERC20 token
    /// @return - The allowance (uint256) e.g 1000
    function checkAllowance(address txFrom, IERC20 token) public view returns (uint256) {
        uint256 providedAllowance = token.allowance(txFrom, address(this));
        return providedAllowance;
    }

    // extracts multisig signature
    function extractECDSASignatures(
        bytes memory _fullSignature
    ) public pure returns (bytes memory signature1, bytes memory signature2) {
        signature1 = new bytes(_fullSignature.length / 2);
        signature2 = new bytes(_fullSignature.length / 2);

        // Copying the first signature. Note, that we need an offset of 0x20
        // since it is where the length of the `_fullSignature` is stored
        assembly {
            let r := mload(add(_fullSignature, 0x20))
            let s := mload(add(_fullSignature, 0x40))
            let v := and(mload(add(_fullSignature, 0x41)), 0xff)

            mstore(add(signature1, 0x20), r)
            mstore(add(signature1, 0x40), s)
            mstore8(add(signature1, 0x60), v)
        }

        // Copying the second signature.
        assembly {
            let r := mload(add(_fullSignature, 0x61))
            let s := mload(add(_fullSignature, 0x81))
            let v := and(mload(add(_fullSignature, 0x82)), 0xff)

            mstore(add(signature2, 0x20), r)
            mstore(add(signature2, 0x40), s)
            mstore8(add(signature2, 0x60), v)
        }
    }

    // extracts single ECDSA signature
    function extractECDSASignature(
        bytes memory _partialSignature
    ) public pure returns (bytes memory signature) {
        signature = new bytes(_partialSignature.length);
        assembly {
            let r := mload(add(_partialSignature, 0x20))
            let s := mload(add(_partialSignature, 0x40))
            let v := and(mload(add(_partialSignature, 0x41)), 0xff)

            mstore(add(signature, 0x20), r)
            mstore(add(signature, 0x40), s)
            mstore8(add(signature, 0x60), v)
        }
    }

    /// @dev this functions checks if the delegating paymaster is a sibling
    /// because only a sibling paymaster can delegate its userOp to another sibling
    /// @param delegateNamehash the subdomain namehash that is originally meant to pay the gas fee
    /// @return  - true / false
    function useDelegate(
        bytes32[] memory self,
        bytes32 delegateNamehash
    ) public pure returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (delegateNamehash == self[i]) return true;
        }
        return false;
    }

    /**
     * @dev checks that this paymaster can sponsor gas on behalf of another paymaster
     * @param destNamehash originally intended paymaster
     */
    function previewDelegation(
        bytes32[] storage siblings,
        bytes32 destNamehash
    ) public pure returns (bool truthy) {
        truthy = true; // true & true = true, true & false = false, false & false = false.
        // currently, the validator must be the same for the two core for delegation to work.
        truthy = truthy && useDelegate(siblings, destNamehash);
    }

    /**
     * @notice gets the actual number of signatures passed with the userOp in paymasterInput
     * @param signatures an array of signature
     * @dev 0 means we don't know the length of the signature.
     * i.e you should always explicitly check for the length if this method returns 0
     */
    function total(bytes calldata signatures) public pure returns (uint256) {
        return
            signatures.length == 64 || signatures.length == 65
                ? 1
                : signatures.length == 128 || signatures.length == 130
                ? 2
                : 0;
    }
}
