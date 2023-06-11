// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@ens/contracts/registry/ENSRegistry.sol";

contract DeployENSRegistryScript is Script {
    function run() external {
        bytes32 salt = keccak256(abi.encodePacked(bytes32("ENS_REGISTRY"), msg.sender));
        vm.startBroadcast();
        new ENSRegistry{salt: salt}();
        vm.stopBroadcast();
    }
}
