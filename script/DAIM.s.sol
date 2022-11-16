// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DAIM} from "../src/DAIM.sol";

contract DAIMScript is Script {
    function setUp() public {}

    function run() public returns (DAIM daim) {
        vm.broadcast();
        daim = new DAIM();
        vm.stopBroadcast();
    }
}
