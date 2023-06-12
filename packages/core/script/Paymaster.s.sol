// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {IEntryPoint} from "@aa/contracts/samples/SimpleAccount.sol";
import {ENS} from "@ens/contracts/registry/ENS.sol";
import {UsernamesPaymaster} from "@usernames/Paymaster.sol";

contract DeployPaymasterScript is Script {
    function run() external {
        IEntryPoint entrypoint = IEntryPoint(0xAB395C5a16C6317f35bC88fE5fE2456ef9e0e708);
        ENS ens = ENS(0xFf1EcF1092C5FfA07ed0c9bcdCd397E456e4095b);
        vm.startBroadcast();
        new UsernamesPaymaster(entrypoint, ens, address(0));
        vm.stopBroadcast();
    }
}
