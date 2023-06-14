// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@ens/contracts/registry/ENS.sol";
import "@ens/contracts/ethregistrar/BaseRegistrarImplementation.sol";
import "@usernames/registrars/UsernamesRegistrarController.sol";
import "@usernames/registrars/ReverseRegistrar.sol";
import {UsernamesResolver} from "@usernames/resolvers/UsernamesResolver.sol";
import {NameWrapper, IMetadataService} from "@usernames/utils/NameWrapper.sol";

contract DeployNameServiceScript is Script {
    function run() external {
        vm.startBroadcast();

        ENS ens = ENS(0xFf1EcF1092C5FfA07ed0c9bcdCd397E456e4095b); // address needed
        BaseRegistrarImplementation baseRegistrar;
        UsernamesRegistrarController baseRegistrarController;
        ReverseRegistrar reverseRegistrar;
        UsernamesResolver publicResolver;
        NameWrapper nameWrapper;

        bytes32 TLD_LABEL = keccak256("bit");
        bytes32 RESOLVER_LABEL = keccak256("resolver");
        bytes32 REVERSE_REGISTRAR_LABEL = keccak256("reverse");
        bytes32 ADDR_LABEL = keccak256("addr");

        bytes32 resolverNode = namehash(bytes32(0), RESOLVER_LABEL);
        bytes32 reverseNode = namehash(bytes32(0), REVERSE_REGISTRAR_LABEL);
        bytes32 rootNode = namehash(bytes32(0), TLD_LABEL);

        // set up base registrar
        baseRegistrar = new BaseRegistrarImplementation(ens, rootNode);
        ens.setSubnodeOwner(bytes32(0), TLD_LABEL, address(baseRegistrar));

        // Set up the reverse registrar
        reverseRegistrar = new ReverseRegistrar(ens);
        ens.setSubnodeOwner(bytes32(0), REVERSE_REGISTRAR_LABEL, msg.sender);
        ens.setSubnodeOwner(reverseNode, ADDR_LABEL, address(reverseRegistrar));

        // Set up the registrar controller
        nameWrapper = new NameWrapper(ens, baseRegistrar, IMetadataService(address(0)));
        baseRegistrarController = new UsernamesRegistrarController(
            baseRegistrar,
            reverseRegistrar,
            nameWrapper,
            ens
        );
        baseRegistrar.addController(msg.sender);
        baseRegistrar.addController(address(baseRegistrarController));

        // setup the resolver
        publicResolver = new UsernamesResolver(
            ens,
            nameWrapper,
            address(baseRegistrarController),
            address(reverseRegistrar)
        );
        baseRegistrar.setResolver(address(publicResolver));

        // Set up the public resolver
        ens.setSubnodeOwner(bytes32(0), RESOLVER_LABEL, msg.sender);
        ens.setResolver(resolverNode, address(publicResolver));
        publicResolver.setAddr(resolverNode, address(publicResolver));
    }

    function namehash(bytes32 node, bytes32 label) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }
}
