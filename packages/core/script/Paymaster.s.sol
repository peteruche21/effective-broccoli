// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {IEntryPoint} from "@aa/contracts/samples/SimpleAccount.sol";
import {ENS} from "@ens/contracts/registry/ENS.sol";
import {UsernamesPaymaster, IERC20Metadata} from "@usernames/Paymaster.sol";

contract DeployPaymasterScript is Script {
    function run() external {
        vm.startBroadcast();
        IEntryPoint entrypoint = IEntryPoint(0xAB395C5a16C6317f35bC88fE5fE2456ef9e0e708);
        ENS ens = ENS(0xFf1EcF1092C5FfA07ed0c9bcdCd397E456e4095b);
        new UsernamesPaymaster(entrypoint, ens, 0x700a89Ba8F908af38834B9Aba238b362CFfB665F);
    }
}
