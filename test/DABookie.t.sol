// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DABookie.sol";

contract DABookieTest is Test {
    DABookie public bets;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(0));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(bets));
        _;
    }

    modifier assumeSufficientStake(address better, uint256 stake) {
        deal(better, stake);
        vm.assume(stake > bets.minStake());
        _;
    }

    modifier assumeValidDates(
        uint256 placeBetDeadline,
        uint256 validationDate
    ) {
        vm.assume(validationDate >= placeBetDeadline);
        _;
    }

    function setUp() public {
        bets = new DABookie();
    }

    function testCreateBetWithStake(
        address creator,
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint256 stake
    )
        public
        assumeValidAddress(creator)
        assumeSufficientStake(creator, stake)
        assumeValidDates(placeBetDeadline, validationDate)
    {
        vm.prank(creator);

        bets.create{value: stake}(
            description,
            bet,
            placeBetDeadline,
            validationDate
        );

        assertEq(address(bets).balance, stake);
        // TODO: how to test if bet was created correctly?
    }

    function testCreateBetInvalidAddress() public {
        vm.prank(address(0));

        vm.expectRevert(InvalidAddress.selector);
        bets.create{value: 0}("", "", 0, 0);
    }

    function testCreateBetInsufficientStake(
        address creator,
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint256 stake
    )
        public
        assumeValidAddress(creator)
        assumeValidDates(placeBetDeadline, validationDate)
    {
        vm.assume(stake < bets.minStake());

        deal(creator, stake);
        vm.prank(creator);
        vm.expectRevert(InsufficientStake.selector);
        bets.create{value: stake}(
            description,
            bet,
            placeBetDeadline,
            validationDate
        );
    }

    function testCreateBetInvalidDates(
        address creator,
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint256 stake
    ) public assumeValidAddress(creator) assumeSufficientStake(creator, stake) {
        vm.prank(creator);
        vm.assume(validationDate < placeBetDeadline);
        vm.expectRevert(InvalidDates.selector);
        bets.create{value: stake}(
            description,
            bet,
            placeBetDeadline,
            validationDate
        );
    }

    function testPlaceBetExisting(
        address creator,
        address player,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint64 stake
    )
        public
        assumeValidAddress(creator)
        assumeValidAddress(player)
        assumeSufficientStake(creator, stake)
        assumeSufficientStake(player, stake)
        assumeValidDates(placeBetDeadline, validationDate)
    {
        vm.assume(block.timestamp < placeBetDeadline);
        vm.assume(creator != player);
        uint256 id = _createBet(
            creator,
            "",
            "",
            placeBetDeadline,
            validationDate,
            stake
        );

        vm.prank(player);
        bets.placeBet{value: stake}(id, "");
        assertEq(address(bets).balance, uint256(stake) * 2);

        // TODO: how to test if bet was placed correctly?
    }

    function testPlaceBetUnexisting(
        uint256 id,
        address player,
        string calldata bet,
        uint256 stake
    ) public assumeValidAddress(player) assumeSufficientStake(player, stake) {
        vm.expectRevert(BetNotFound.selector);
        vm.prank(player);
        bets.placeBet{value: stake}(id, bet);
    }

    function testPlaceBetInsufficientStake(
        address creator,
        address player,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint64 creatorStake,
        uint64 playerStake
    )
        public
        assumeValidAddress(creator)
        assumeValidAddress(player)
        assumeSufficientStake(creator, creatorStake)
        assumeValidDates(placeBetDeadline, validationDate)
    {
        vm.assume(block.timestamp < placeBetDeadline);
        vm.assume(creator != player);
        uint256 id = _createBet(
            creator,
            "",
            "",
            placeBetDeadline,
            validationDate,
            creatorStake
        );

        vm.assume(playerStake > 0 && playerStake < bets.minStake());
        deal(player, playerStake);
        vm.prank(player);
        vm.expectRevert(InsufficientStake.selector);
        bets.placeBet{value: playerStake}(id, "");
    }

    function testPlaceBetClosed(
        address creator,
        address player,
        uint128 placeBetDeadline,
        uint128 validationDate,
        uint64 stake
    )
        public
        assumeValidAddress(creator)
        assumeValidAddress(player)
        assumeSufficientStake(creator, stake)
        assumeSufficientStake(player, stake)
        assumeValidDates(placeBetDeadline, validationDate)
    {
        vm.assume(creator != player);
        vm.assume(block.timestamp > placeBetDeadline);
        uint256 id = _createBet(
            creator,
            "",
            "",
            placeBetDeadline,
            validationDate,
            uint256(stake)
        );

        vm.prank(player);
        vm.expectRevert(ClosedBets.selector);
        bets.placeBet{value: uint256(stake)}(id, "");
    }

    function _createBet(
        address creator,
        string memory description,
        string memory bet,
        uint256 placeBetDeadline,
        uint256 validationDate,
        uint256 stake
    ) public returns (uint256) {
        deal(creator, stake);
        vm.prank(creator);
        return
            bets.create{value: stake}(
                description,
                bet,
                placeBetDeadline,
                validationDate
            );
    }
}
