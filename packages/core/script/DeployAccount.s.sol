// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "@aa/contracts/samples/SimpleAccount.sol";

contract DeploySimpleAccountScript is Script {
    function run() external {
        bytes32 salt = keccak256(abi.encodePacked(bytes32("SIMPLE_ACCOUNT"), msg.sender));
        IEntryPoint entrypoint;
        vm.startBroadcast();
        new SimpleAccount{salt: salt}(entrypoint);
        vm.stopBroadcast();
    }
}
