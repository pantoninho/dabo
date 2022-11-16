// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {DAIM} from "../src/DAIM.sol";
import {DAIMarkets} from "../src/DAIMarkets.sol";
import {DAIBookie} from "../src/DAIBookie.sol";
import "../src/Errors.sol";

contract DAIBookieTest is Test {
    DAIM public daim;
    DAIMarkets public bets;
    DAIBookie public bookie;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(10));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(daim.factx()));
        vm.assume(a != address(daim.fact()));
        vm.assume(a != address(daim.bookie()));
        vm.assume(a != address(daim.bets()));
        vm.assume(a != address(daim.treasury()));
        vm.assume(a != address(daim.office()));
        vm.assume(a != address(0x4e59b44847b379578588920cA78FbF26c0B4956C)); // create2deployer? wtf is this?
        _;
    }

    function setUp() public {
        daim = new DAIM();
        bets = daim.bets();
        bookie = daim.bookie();
    }

    function testAddProposalNotBoookie() public {
        DAIMarkets.Proposal memory proposal;

        vm.expectRevert(Unauthorized.selector);
        bets.addProposal(proposal);
    }

    function testAddProposalFromBookie() public {
        DAIMarkets.Proposal memory proposal;

        vm.prank(address(bookie));
        uint256 id = bets.addProposal(proposal);

        assertTrue(id > 0);
    }

    function testPlaceBetNotBookie(
        uint256 proposalId,
        address player,
        string memory bet,
        uint256 stake
    ) public assumeValidAddress(player) {
        vm.expectRevert(Unauthorized.selector);
        bets.placeBet(proposalId, player, bet, stake);
    }

    function testPlaceBetNoStake(
        uint256 proposalId,
        address player,
        string memory bet
    ) public assumeValidAddress(player) {
        vm.startPrank(address(bookie));
        vm.expectRevert(InsufficientStake.selector);
        bets.placeBet(proposalId, player, bet, 0);
    }

    function testPlaceBetUnexistingProposal(
        uint256 proposalId,
        address player,
        string memory bet,
        uint256 stake
    ) public assumeValidAddress(player) {
        vm.assume(stake > 0);
        vm.prank(address(bookie));
        vm.expectRevert(ProposalNotFound.selector);
        bets.placeBet(proposalId, player, bet, stake);
    }

    function testPlaceBetExistingProposal(
        address player1,
        address player2,
        string memory bet,
        uint64 stake
    ) public assumeValidAddress(player1) assumeValidAddress(player2) {
        vm.assume(stake > 0);
        vm.assume(player1 != player2);
        vm.startPrank(address(bookie));

        DAIMarkets.Proposal memory proposal;
        uint256 proposalId = bets.addProposal(proposal);

        uint256 bet1Id = bets.placeBet(proposalId, player1, bet, stake);
        uint256 bet2Id = bets.placeBet(proposalId, player2, bet, stake);

        assertEq(bet1Id, bet2Id); // if bet is same string in same proposal, should have same bet id
        assertEq(bets.getProposalByBetId(bet1Id).id, proposalId);

        uint256 betStake = uint256(stake) * 2; // because both players betted on the same outcome with the same stake

        assertEq(bets.getStakeOnBet(bet1Id), betStake);
        assertEq(bets.getPlayerStakeOnBet(player1, bet1Id), stake);
        assertEq(bets.getPlayerStakeOnBet(player2, bet1Id), stake);
        assertEq(bets.getProposal(proposalId).betPool, betStake);
    }

    function testCalculateRewardsDifferentBets(
        address player1,
        address player2,
        uint64 p1stake,
        uint64 p2stake
    ) public assumeValidAddress(player1) assumeValidAddress(player2) {
        vm.assume(p1stake > 0);
        vm.assume(p2stake > 0);
        vm.assume(player1 != player2);
        vm.startPrank(address(bookie));

        DAIMarkets.Proposal memory proposal;
        uint256 proposalId = bets.addProposal(proposal);

        uint256 bet1Id = bets.placeBet(proposalId, player1, "bet 1", p1stake);
        uint256 bet2Id = bets.placeBet(proposalId, player2, "bet 2", p2stake);
        uint256 expectedRewards = uint256(p1stake) + uint256(p2stake);

        uint256 p1Rewards = bets.calculateRewards(player1, bet1Id);
        uint256 p2Rewards = bets.calculateRewards(player2, bet2Id);

        assertEq(p1Rewards, expectedRewards);
        assertEq(p2Rewards, expectedRewards);
    }

    function testCalculateRewardsSameBet(
        address player1,
        address player2,
        uint64 p1stake,
        uint64 p2stake,
        string memory bet
    ) public assumeValidAddress(player1) assumeValidAddress(player2) {
        vm.assume(p1stake > 0);
        vm.assume(p2stake > 0);
        vm.assume(player1 != player2);
        vm.startPrank(address(bookie));

        DAIMarkets.Proposal memory proposal;
        uint256 proposalId = bets.addProposal(proposal);

        uint256 bet1Id = bets.placeBet(proposalId, player1, bet, p1stake);
        uint256 bet2Id = bets.placeBet(proposalId, player2, bet, p2stake);

        uint256 p1Rewards = bets.calculateRewards(player1, bet1Id);
        uint256 p2Rewards = bets.calculateRewards(player2, bet2Id);

        uint256 betStake = uint256(p1stake) + uint256(p2stake);

        assertEq(p1Rewards, _calculateBetRewards(p1stake, betStake, betStake));
        assertEq(p2Rewards, _calculateBetRewards(p2stake, betStake, betStake));
    }

    function _calculateBetRewards(
        uint256 playerStake,
        uint256 betStake,
        uint256 betPool
    ) internal pure returns (uint256 rewards) {
        return ((betPool * playerStake) / betStake);
    }
}
