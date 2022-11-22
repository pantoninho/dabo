// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DAIM} from "../src/DAIM.sol";
import {DAIMTreasury} from "../src/DAIMTreasury.sol";
import {FACTx} from "../src/FACTx.sol";

contract DAIMScript is Script {
    DAIM daim;

    struct Bet {
        uint256 pkey;
        string bet;
        uint256 stake;
    }

    function setUp() public {}

    function run() public {
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );

        vm.stopBroadcast();
    }
}
