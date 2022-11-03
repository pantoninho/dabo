// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DABookie.sol";
import "../src/DABCatalogue.sol";

contract DABookieTest is Test {
    DABookie public bookie;
    DABCatalogue public bets;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(0));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(bookie));
        _;
    }

    modifier assumeSufficientStake(uint256 stake) {
        vm.assume(stake > bookie.minStake());
        _;
    }

    function setUp() public {
        bookie = new DABookie();
        bets = bookie.bets();
    }

    function testCreateBetWithStake(
        address creator,
        string memory bet,
        uint256 stake
    ) public assumeValidAddress(creator) assumeSufficientStake(stake) {
        uint256 fakeId = 10;
        _mockBetCreation(fakeId, 0);

        hoax(creator, stake);
        uint256 id = bookie.create{value: stake}("", bet, 0, 0);

        assertEq(id, fakeId);
        assertEq(address(bookie).balance, stake);
        assertEq(bookie.getBetStake(id), stake);
        assertEq(bookie.getPlacedBetStake(id, bet), stake);
        assertEq(bookie.getPlayerStake(creator, id, bet), stake);
    }

    function testCreateBetInsufficientStake(address creator, uint256 stake)
        public
        assumeValidAddress(creator)
    {
        vm.assume(stake < bookie.minStake());

        hoax(creator, stake);
        vm.expectRevert(InsufficientStake.selector);
        bookie.create{value: stake}("", "", 0, 100);
    }

    function testPlaceBetExisting(
        address player1,
        address player2,
        string memory player1Bet,
        string memory player2Bet,
        uint64 player1Stake,
        uint64 player2Stake,
        uint256 placeBetDeadline,
        uint256 when
    )
        public
        assumeValidAddress(player1)
        assumeValidAddress(player2)
        assumeSufficientStake(player1Stake)
        assumeSufficientStake(player2Stake)
    {
        vm.assume(when < placeBetDeadline);
        vm.assume(player1 != player2);
        vm.assume(
            keccak256(abi.encodePacked(player1Bet)) !=
                keccak256(abi.encodePacked(player2Bet))
        );

        uint256 fakeId = 10;
        _mockBetCreation(fakeId, placeBetDeadline);

        vm.warp(when);
        _placeBet(fakeId, player1, player1Bet, player1Stake);
        _placeBet(fakeId, player2, player2Bet, player2Stake);

        // total bookie balance should be the sum of the two stakes
        assertEq(
            address(bookie).balance,
            uint256(player1Stake) + uint256(player2Stake)
        );
        // total bet stake should be the sum of the two stakes
        assertEq(
            bookie.getBetStake(fakeId),
            uint256(player1Stake) + uint256(player2Stake)
        );

        // each player's placed bet stake should be his own staked value
        assertEq(bookie.getPlacedBetStake(fakeId, player1Bet), player1Stake);
        assertEq(bookie.getPlacedBetStake(fakeId, player2Bet), player2Stake);

        // each player's stake on each placed bet should be his own staked value
        assertEq(
            bookie.getPlayerStake(player1, fakeId, player1Bet),
            player1Stake
        );
        assertEq(
            bookie.getPlayerStake(player2, fakeId, player2Bet),
            player2Stake
        );
    }

    function testPlaceBetExistingAndSame(
        address player1,
        address player2,
        string memory bet,
        uint64 player1Stake,
        uint64 player2Stake,
        uint256 placeBetDeadline,
        uint256 when
    )
        public
        assumeValidAddress(player1)
        assumeValidAddress(player2)
        assumeSufficientStake(player1Stake)
        assumeSufficientStake(player2Stake)
    {
        vm.assume(when < placeBetDeadline);
        vm.assume(player1 != player2);

        uint256 fakeId = 10;
        _mockBetCreation(fakeId, placeBetDeadline);

        vm.warp(when);
        _placeBet(fakeId, player1, bet, player1Stake);
        _placeBet(fakeId, player2, bet, player2Stake);

        // total bookie balance should be the sum of the two stakes
        assertEq(
            address(bookie).balance,
            uint256(player1Stake) + uint256(player2Stake)
        );
        // total bet stake should be the sum of the two stakes
        assertEq(
            bookie.getBetStake(fakeId),
            uint256(player1Stake) + uint256(player2Stake)
        );

        // placed bet should be the sum of the two stakes
        assertEq(
            bookie.getPlacedBetStake(fakeId, bet),
            uint256(player1Stake) + uint256(player2Stake)
        );

        // each player's stake on each placed bet should be his own staked value
        assertEq(bookie.getPlayerStake(player1, fakeId, bet), player1Stake);
        assertEq(bookie.getPlayerStake(player2, fakeId, bet), player2Stake);
    }

    function testPlaceBetUnexisting(
        uint256 id,
        address player,
        string calldata bet,
        uint256 stake
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.expectRevert(BetNotFound.selector);
        _placeBet(id, player, bet, stake);
    }

    function testPlaceBetInsufficientStake(
        address player,
        string memory bet,
        uint64 stake
    ) public assumeValidAddress(player) {
        vm.assume(stake < bookie.minStake());

        uint256 fakeId = 10;
        _mockBetCreation(fakeId, 1000);

        vm.expectRevert(InsufficientStake.selector);
        _placeBet(fakeId, player, bet, stake);
    }

    function testPlaceBetClosed(
        address player,
        string memory bet,
        uint128 placeBetDeadline,
        uint64 stake,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when > placeBetDeadline);

        uint256 fakeId = 10;
        _mockBetCreation(fakeId, placeBetDeadline);

        vm.warp(when);
        vm.expectRevert(ClosedBets.selector);
        _placeBet(fakeId, player, bet, stake);
    }

    function testClaimPrizeUnvalidated() public {
        _mockBetCreation(10, 1000);
        vm.prank(address(11));

        vm.expectRevert(BetNotValidated.selector);
        bookie.claimPrize(10);
    }

    function testClaimPrizeSingleWinner() public {
        string[] memory validBets = new string[](1);
        validBets[0] = "winner";
        _mockBetCreation(10, 1000, true, validBets);
        vm.warp(0);

        _placeBet(10, address(11), "winner", 1 ether);
        _placeBet(10, address(12), "loser", 1 ether);
        _placeBet(10, address(13), "loser", 1 ether);

        vm.prank(address(11));
        bookie.claimPrize(10);

        assertEq(address(11).balance, 3 ether);
    }

    function testClaimPrizeMultipleWinners() public {
        string[] memory validBets = new string[](1);
        validBets[0] = "winner";
        _mockBetCreation(10, 1000, true, validBets);
        vm.warp(0);

        _placeBet(10, address(11), "winner", 1 ether);
        _placeBet(10, address(12), "winner", 2 ether);
        _placeBet(10, address(13), "loser", 1 ether);

        vm.prank(address(11));
        bookie.claimPrize(10);

        vm.prank(address(12));
        bookie.claimPrize(10);

        assertApproxEqAbs(address(11).balance, 1.3 ether, 0.1 ether);
        assertApproxEqAbs(address(12).balance, 2.6 ether, 0.1 ether);

        emit log_uint(address(12).balance);
    }

    function _mockBetCreation(uint256 fakeId, uint256 placeBetDeadline)
        internal
    {
        string[] memory validBets;
        _mockBetCreation(fakeId, placeBetDeadline, false, validBets);
    }

    function _mockBetCreation(
        uint256 fakeId,
        uint256 placeBetDeadline,
        bool validated,
        string[] memory validBets
    ) internal {
        vm.assume(placeBetDeadline < type(uint128).max); // prevent various types of overflow in fuzzy tests

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(DABCatalogue.create.selector),
            abi.encode(fakeId)
        );

        DABCatalogue.Bet memory _bet;
        _bet.placeBetDeadline = placeBetDeadline;
        _bet.validationDate = placeBetDeadline + 100;
        _bet.validated = validated;
        _bet.validBets = validBets;

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(DABCatalogue.get.selector),
            abi.encode(_bet)
        );
    }

    function _placeBet(
        uint256 betId,
        address player,
        string memory bet,
        uint256 stake
    ) internal {
        hoax(player, stake);
        bookie.placeBet{value: stake}(betId, bet);
    }
}
