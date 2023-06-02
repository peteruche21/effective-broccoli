// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@ens/contracts/registry/ENS.sol";

contract FIFSRegistrar {
    ENS ens;
    bytes32 rootNode;

    modifier only_owner(bytes32 label) {
        address currentOwner = ens.owner(keccak256(abi.encodePacked(rootNode, label)));
        require(currentOwner == address(0x0) || currentOwner == msg.sender);
        _;
    }

    constructor(ENS ensAddr, bytes32 node) {
        ens = ensAddr;
        rootNode = node;
    }

    function register(bytes32 label, address owner) public only_owner(label) {
        ens.setSubnodeOwner(rootNode, label, owner);
    }
}
