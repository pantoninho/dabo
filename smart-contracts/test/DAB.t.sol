// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {FACT} from "../src/FACT.sol";
import {DAIMTreasury} from "../src/DAIMTreasury.sol";

contract FACTTest is Test {
    DAIMTreasury public treasury;
    FACT public fact;
    uint256 maxSupply = 10;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(0));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(treasury));
        vm.assume(a != address(fact));
        _;
    }

    function setUp() public {
        treasury = new DAIMTreasury(10);
        fact = treasury.fact();
    }

    function testMintByTreasury(address to, uint256 amount)
        public
        assumeValidAddress(to)
    {
        vm.startPrank(address(treasury));
        vm.assume(amount > 1 && amount < maxSupply / 2);

        // mint amount until maxSupply is *almost* reached
        for (uint256 i = 0; i + amount <= maxSupply; i += amount) {
            fact.mint(to, amount);
        }

        // maxSupply should be reached here
        vm.expectRevert(FACT.MaxSupplyReached.selector);
        fact.mint(to, amount);
    }

    function testMintByOther(
        address from,
        address to,
        uint256 amount
    ) public assumeValidAddress(from) assumeValidAddress(to) {
        vm.startPrank(address(from));
        vm.expectRevert(FACT.Unauthorized.selector);

        fact.mint(to, amount);
    }
}
