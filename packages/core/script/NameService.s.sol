// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@ens/contracts/registry/ENS.sol";
import "@ens/contracts/ethregistrar/BaseRegistrarImplementation.sol";
import "@usernames/registrars/UsernamesRegistrarController.sol";
import "@usernames/registrars/ReverseRegistrar.sol";
import {UsernamesResolver, INameWrapper} from "@usernames/resolvers/UsernamesResolver.sol";

contract DeployNameServiceScript is Script {
    bytes32 constant TLD_LABEL = keccak256("bit");
    bytes32 constant RESOLVER_LABEL = keccak256("resolver");
    bytes32 constant REVERSE_REGISTRAR_LABEL = keccak256("reverse");
    bytes32 constant ADDR_LABEL = keccak256("addr");

    ENS ens = ENS(0xFf1EcF1092C5FfA07ed0c9bcdCd397E456e4095b); // address needed
    BaseRegistrarImplementation baseRegistrar;
    UsernamesRegistrarController baseRegistrarController;
    ReverseRegistrar reverseRegistrar;
    UsernamesResolver publicResolver;

    function run() external {
        vm.startBroadcast();

        // set up base registrar
        baseRegistrar = new BaseRegistrarImplementation(ens, namehash(bytes32(0), TLD_LABEL));
        ens.setSubnodeOwner(bytes32(0), TLD_LABEL, address(baseRegistrar));
        baseRegistrar.addController(msg.sender);

        // Construct a new reverse registrar and point it at the public resolver
        reverseRegistrar = new ReverseRegistrar(ens);

        // Set up the reverse registrar
        ens.setSubnodeOwner(bytes32(0), REVERSE_REGISTRAR_LABEL, msg.sender);
        ens.setSubnodeOwner(
            namehash(bytes32(0), REVERSE_REGISTRAR_LABEL),
            ADDR_LABEL,
            address(reverseRegistrar)
        );

        // Set up the registrar controller
        baseRegistrarController = new UsernamesRegistrarController(
            baseRegistrar,
            reverseRegistrar,
            INameWrapper(address(0)),
            ens
        );
        baseRegistrar.addController(address(baseRegistrarController));

        // setup the resolver
        publicResolver = new UsernamesResolver(
            ens,
            INameWrapper(address(0)),
            address(baseRegistrarController),
            address(reverseRegistrar)
        );
        bytes32 resolverNode = namehash(bytes32(0), RESOLVER_LABEL);

        ens.setSubnodeOwner(bytes32(0), RESOLVER_LABEL, msg.sender);
        ens.setResolver(resolverNode, address(publicResolver));
        publicResolver.setAddr(resolverNode, address(publicResolver));
        baseRegistrar.setResolver(address(publicResolver));

        vm.stopBroadcast();
    }

    function namehash(bytes32 node, bytes32 label) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }
}
