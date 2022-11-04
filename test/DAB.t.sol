// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DAB.sol";
import "../src/DABOTreasury.sol";

contract DABTest is Test {
    DABOTreasury public treasury;
    DAB public dab;
    uint256 maxSupply = 10;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(0));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(treasury));
        vm.assume(a != address(dab));
        _;
    }

    function setUp() public {
        treasury = new DABOTreasury(maxSupply);
        dab = treasury.dab();
    }

    function testMintByTreasury(address to, uint256 amount)
        public
        assumeValidAddress(to)
    {
        vm.startPrank(address(treasury));
        vm.assume(amount > 1 && amount < maxSupply / 2);

        // mint amount until maxSupply is *almost* reached
        for (uint256 i = 0; i + amount <= maxSupply; i += amount) {
            dab.mint(to, amount);
        }

        // maxSupply should be reached here
        vm.expectRevert(DAB.MaxSupplyReached.selector);
        dab.mint(to, amount);
    }

    function testMintByOther(address from, address to, uint256 amount)
        public
        assumeValidAddress(from)
        assumeValidAddress(to)
    {
        vm.startPrank(address(from));
        vm.expectRevert(DAB.Unauthorized.selector);

        dab.mint(to, amount);
    }
}
