// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@aa/contracts/core/EntryPoint.sol";

contract DeployEntrypointScript is Script {
    function run() external {
        vm.startBroadcast();
        new EntryPoint();
        vm.stopBroadcast();
    }
}
