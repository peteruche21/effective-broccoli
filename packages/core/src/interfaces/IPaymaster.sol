// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@aa/contracts/interfaces/IPaymaster.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IENSPaymaster is IPaymaster {
    function getHash(
        UserOperation calldata userOp,
        bytes32 nodeHash,
        uint48 validUntil,
        uint48 validAfter
    ) external view returns (bytes32);

    function setNodeSigners(
        address primarySigner,
        address secondarySigner,
        bytes32 node,
        uint8 sigCount
    ) external;

    function addToken(IERC20 token, address priceFeed) external;

    function fundNode(bytes32 node) external payable;

    function withdraw(bytes32 node) external;
}
