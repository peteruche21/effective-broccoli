// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@ens/contracts/registry/ENSRegistry.sol";

contract DeployENSRegistryScript is Script {
    function run() external {
        vm.startBroadcast();
        new ENSRegistry();
        vm.stopBroadcast();
    }
}
