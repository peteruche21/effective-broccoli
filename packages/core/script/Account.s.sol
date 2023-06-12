// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@aa/contracts/samples/SimpleAccount.sol";

contract DeployAccountScript is Script {
    function run() external {
        IEntryPoint entrypoint = IEntryPoint(0xAB395C5a16C6317f35bC88fE5fE2456ef9e0e708);
        vm.startBroadcast();
        new SimpleAccount(entrypoint);
        vm.stopBroadcast();
    }
}
