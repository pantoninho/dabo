// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DABookie.sol";
import "../src/DABets.sol";
import "../src/DABV.sol";
import "../src/DAB.sol";
import "../src/DABOffice.sol";

contract DABVMock is DABV {
    constructor(IERC20 asset) DABV(asset) {}
}

contract DABookieTest is Test {
    DABookie public bookie;
    DABets public bets;
    DABV public dabvMock;
    DABOTreasury public daboTreasury;
    DAB public dab;
    DABOffice public office;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(10));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(bookie));
        vm.assume(a != address(bets));
        vm.assume(a != address(dab));
        vm.assume(a != address(dabvMock));
        vm.assume(a != address(daboTreasury));
        vm.assume(a != address(office));
        vm.assume(a != address(0x4e59b44847b379578588920cA78FbF26c0B4956C)); // create2deployer? wtf is this?
        _;
    }

    modifier assumeSufficientStake(uint256 stake) {
        vm.assume(stake > bookie.minStake());
        _;
    }

    function setUp() public {
        daboTreasury = new DABOTreasury(1000);
        dab = new DAB(1000, daboTreasury);
        dabvMock = new DABV(dab);
        bookie = new DABookie(dabvMock);
        bets = bookie.bets();
        office = bookie.office();
    }

    function testCreateProposalWithoutBet(
        address creator,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(creator) {
        vm.assume(when < betsClosedAt);
        uint256 proposalId = 10;
        _mockProposal(proposalId, betsClosedAt);

        hoax(creator);
        vm.warp(when);
        uint256 id = bookie.propose("", 0, 0);

        assertEq(id, proposalId);
    }

    function testCreateProposalWithBetEnoughStake(
        address creator,
        string memory bet,
        uint256 stake,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(creator) assumeSufficientStake(stake) {
        vm.assume(when < betsClosedAt);
        uint256 proposalId = 10;
        _mockProposal(proposalId, betsClosedAt); // this is required to mock the inner placeBet call with this proposalId

        hoax(creator, stake);
        vm.warp(when);
        uint256 id = bookie.propose{value: stake}("", bet, 0, 0);

        assertEq(id, proposalId);
        assertEq(address(bookie).balance, stake);
    }

    function testCreateProposalWithInvalidDates(
        address creator,
        uint256 stake,
        uint256 betsClosedAt,
        uint256 readyForValidationAt
    ) public assumeValidAddress(creator) assumeSufficientStake(stake) {
        vm.assume(betsClosedAt > readyForValidationAt);

        hoax(creator, stake);
        vm.warp(betsClosedAt);
        vm.expectRevert(InvalidDates.selector);
        bookie.propose("", betsClosedAt, readyForValidationAt);
    }

    function testCreateProposalWithBetInsufficientStake(
        address creator,
        uint256 stake
    ) public assumeValidAddress(creator) {
        vm.assume(stake < bookie.minStake());

        hoax(creator, stake);
        vm.expectRevert(InsufficientStake.selector);
        bookie.propose{value: stake}("", "", 0, 100);
    }

    function testPlaceBetActiveProposal(
        address player,
        string memory bet,
        uint64 stake,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when < betsClosedAt);
        uint256 proposalId = 10;
        _mockProposal(proposalId, betsClosedAt);

        vm.warp(when);
        startHoax(player, stake);
        bookie.placeBet{value: stake}(proposalId, bet);

        assertEq(bookie.getActiveBets().length, 1);
        assertEq(bookie.getActiveBets()[0], proposalId);
        assertEq(address(bookie).balance, stake);
    }

    function testPlaceBetUnexistingProposal(
        uint256 id,
        address player,
        string calldata bet,
        uint256 stake
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.expectRevert(ProposalNotFound.selector);
        _placeBet(id, player, bet, stake);
    }

    function testPlaceBetInsufficientStake(
        address player,
        string memory bet,
        uint64 stake,
        uint256 betsCloseAt,
        uint256 when
    ) public assumeValidAddress(player) {
        vm.assume(stake < bookie.minStake());
        vm.assume(when < betsCloseAt);

        uint256 fakeId = 10;
        _mockProposal(fakeId, betsCloseAt);

        vm.warp(when);
        vm.expectRevert(InsufficientStake.selector);
        _placeBet(fakeId, player, bet, stake);
    }

    function testPlaceBetClosed(
        address player,
        string memory bet,
        uint128 betsClosedAt,
        uint64 stake,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when > betsClosedAt);

        uint256 fakeId = 10;
        _mockProposal(fakeId, betsClosedAt);

        vm.warp(when);
        vm.expectRevert(ClosedBets.selector);
        _placeBet(fakeId, player, bet, stake);
    }

    function testClaimRewardsSingleBet(
        uint256 proposalId,
        address player,
        string memory bet,
        uint64 stake,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when < betsClosedAt);
        _mockProposal(proposalId, betsClosedAt, true);

        vm.warp(when);
        uint256 betId = _placeBet(proposalId, player, bet, stake, true);

        uint256 reward = uint256(stake) * 2;
        vm.deal(address(bookie), reward);

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(
                DABets.calculateRewards.selector,
                player,
                betId
            ),
            abi.encode(reward)
        );

        vm.prank(player);
        bookie.claimRewards();

        assertEq(address(player).balance, reward);
    }

    function testClaimRewardsMultipleTimes(
        uint256 proposalId,
        address player,
        string memory bet,
        uint64 stake,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when < betsClosedAt);
        _mockProposal(proposalId, betsClosedAt, true);

        vm.warp(when);
        uint256 betId = _placeBet(proposalId, player, bet, stake, true);

        uint256 reward = uint256(stake) * 2;
        vm.deal(address(bookie), reward);

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(
                DABets.calculateRewards.selector,
                player,
                betId
            ),
            abi.encode(reward)
        );

        vm.startPrank(player);
        bookie.claimRewards();
        assertEq(address(player).balance, reward);

        bookie.claimRewards();
        assertEq(address(player).balance, reward);
    }

    function testClaimRewardsNotValidated(
        uint256 proposalId,
        address player,
        string memory bet,
        uint64 stake,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when < betsClosedAt);
        _mockProposal(proposalId, betsClosedAt, false);
        vm.warp(when);

        uint256 betId = _placeBet(proposalId, player, bet, stake, false);
        uint256 reward = uint256(stake) * 2;

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(
                DABets.calculateRewards.selector,
                player,
                betId
            ),
            abi.encode(reward)
        );

        vm.prank(player);
        bookie.claimRewards();
        assertEq(address(player).balance, 0);
    }

    function testClaimRewardsNoFunds(
        uint256 proposalId,
        address player,
        string memory bet,
        uint64 stake,
        uint256 betsClosedAt,
        uint256 when
    ) public assumeValidAddress(player) assumeSufficientStake(stake) {
        vm.assume(when < betsClosedAt);
        _mockProposal(proposalId, betsClosedAt, true);

        vm.warp(when);
        uint256 betId = _placeBet(proposalId, player, bet, stake, true);
        uint256 reward = uint256(stake) * 2;

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(
                DABets.calculateRewards.selector,
                player,
                betId
            ),
            abi.encode(reward)
        );

        vm.prank(player);
        vm.expectRevert(RewardsTransferUnsuccessful.selector);
        bookie.claimRewards();
    }

    function _mockProposal(uint256 fakeId, uint256 betsClosedAt) internal {
        _mockProposal(fakeId, betsClosedAt, false);
    }

    function _mockProposal(
        uint256 fakeId,
        uint256 betsClosedAt,
        bool validated
    ) internal {
        vm.assume(betsClosedAt < type(uint128).max); // prevent various types of overflow in fuzzy tests

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(DABets.addProposal.selector),
            abi.encode(fakeId)
        );

        DABets.Proposal memory _bet;
        _bet.betsClosedAt = betsClosedAt;
        _bet.readyForValidationAt = betsClosedAt;
        _bet.validated = validated;

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(DABets.getProposal.selector),
            abi.encode(_bet)
        );

        vm.mockCall(
            address(bets),
            abi.encodeWithSelector(DABets.placeBet.selector, fakeId),
            abi.encode(fakeId)
        );
    }

    function _placeBet(
        uint256 proposalId,
        address player,
        string memory bet,
        uint256 stake
    ) internal returns (uint256 betId) {
        hoax(player, stake);
        return bookie.placeBet{value: stake}(proposalId, bet);
    }

    function _placeBet(
        uint256 proposalId,
        address player,
        string memory bet,
        uint256 stake,
        bool isWinner
    ) internal returns (uint256 betId) {
        betId = _placeBet(proposalId, player, bet, stake);
        vm.mockCall(
            address(office),
            abi.encodeWithSelector(DABOffice.isWinner.selector, betId),
            abi.encode(isWinner)
        );
    }
}
