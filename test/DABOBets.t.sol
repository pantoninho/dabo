// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DABOBets.sol";

contract DABOBetsTest is Test {
    DABOBets public bets;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(0));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(bets));
        _;
    }

    function setUp() public {
        bets = new DABOBets();
    }

    function testCreateBetWithStake(
        address creator,
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint256 stake
    ) public assumeValidAddress(creator) {
        deal(creator, stake);
        vm.prank(creator);
        vm.assume(validationDate >= placeBetDeadline);

        bets.create{value: stake}(
            description,
            bet,
            placeBetDeadline,
            validationDate
        );

        assertEq(address(bets).balance, stake);
    }

    function testCreateBetWithoutStake(
        address creator,
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate
    ) public assumeValidAddress(creator) {
        vm.prank(creator);
        vm.assume(validationDate >= placeBetDeadline);
        vm.expectRevert(DABOBets.NotEnoughStake.selector);
        bets.create(description, bet, placeBetDeadline, validationDate);
    }

    function testCreateBetInvalidDates(
        address creator,
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate
    ) public assumeValidAddress(creator) {
        vm.prank(creator);
        vm.assume(validationDate < placeBetDeadline);
        vm.expectRevert(DABOBets.InvalidDates.selector);
        bets.create(description, bet, placeBetDeadline, validationDate);
    }
}
