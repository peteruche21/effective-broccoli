// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error InvalidConfig();
error OperationFailed();
error InsufficientAllowance();
error NotEnoughValueForGas();
error FailedToValidatedOp();
error InsufficientValue();
error InvalidSignatureLength();
error UnAuthorized();

error Unauthorised(bytes32 node, address addr);
error IncompatibleParent();
error IncorrectTokenType();
error LabelMismatch(bytes32 labelHash, bytes32 expectedLabelhash);
error LabelTooShort();
error LabelTooLong(string label);
error IncorrectTargetOwner(address owner);
error CannotUpgrade();
error OperationProhibited(bytes32 node);
error NameIsNotWrapped();
error NameIsStillExpired();
