// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {FACT} from "../src/FACT.sol";
import {DAIMTreasury} from "../src/DAIMTreasury.sol";

contract FACTTest is Test {
    DAIMTreasury public treasury;
    FACT public fact;
    uint256 maxSupply = 20 ether;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(0));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(treasury));
        vm.assume(a != address(fact));
        _;
    }

    function setUp() public {
        treasury = new DAIMTreasury(maxSupply);
        fact = treasury.fact();
    }

    function testInitializeTreasury(
        address who,
        uint128 weis,
        uint128 factTokens
    ) public assumeValidAddress(who) {
        vm.assume(factTokens > 0.5 ether);
        vm.assume(weis > 0.5 ether);
        hoax(who, uint256(weis) * 2);
        treasury.initialTrade{value: weis}(factTokens);

        vm.prank(who);
        (bool success, ) = address(treasury).call{value: weis}("");

        assertTrue(success);
        assertEq(address(treasury).balance, uint256(weis) * 2);
        assertEq(fact.balanceOf(who), uint256(factTokens) * 2);
    }
}
