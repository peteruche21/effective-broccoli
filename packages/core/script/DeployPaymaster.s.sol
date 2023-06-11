// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {IEntryPoint} from "@aa/contracts/samples/SimpleAccount.sol";
import {ENS} from "@ens/contracts/registry/ENS.sol";
import {UsernamesPaymaster} from "@usernames/Paymaster.sol";

contract DeployPaymasterScript is Script {
    function run() external {
        bytes32 salt = keccak256(abi.encodePacked(bytes32("PAYMASTER"), msg.sender));
        IEntryPoint entrypoint;
        ENS ens;
        vm.startBroadcast();
        new UsernamesPaymaster{salt: salt}(entrypoint, ens, address(0));
        vm.stopBroadcast();
    }
}
