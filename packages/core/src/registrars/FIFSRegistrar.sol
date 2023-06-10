// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@ens/contracts/registry/ENS.sol";

/// @title First in First served subdomain registrar
/// @notice registers a subdomain for users.
// NOTE: the TLD owner has to set this contract as a node operator
contract FIFSRegistrar {
    ENS ens;

    modifier only_owner(bytes32 label, bytes32 node) {
        address currentOwner = ens.owner(keccak256(abi.encodePacked(node, label)));
        require(currentOwner == address(0x0) || currentOwner == msg.sender);
        _;
    }

    ///
    /// @param label domain name e.g `alice`
    /// @param owner who will own this domain
    /// @param node TLD domain nameHash
    function register(bytes32 label, address owner, bytes32 node) public only_owner(label, node) {
        ens.setSubnodeOwner(node, label, owner);
    }
}
