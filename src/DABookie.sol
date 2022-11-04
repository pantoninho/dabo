// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/utils/structs/EnumerableMap.sol";
import "./DABets.sol";
import "./Errors.sol";

import "forge-std/console2.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bookie
 * @notice  TODO: write this
 */
contract DABookie {
    using EnumerableMap for EnumerableMap.UintToUintMap;

    DABets public bets;
    uint256 public constant minStake = 0.01 ether; // TODO: governance should be able to update this
    // address => betId => proposalId
    mapping(address => EnumerableMap.UintToUintMap) betsToClaim;

    constructor() {
        bets = new DABets(this);
    }

    function propose(
        string calldata description, // TODO: calldata or memory?
        uint256 betsClosedAt,
        uint256 readyForValidationAt
    ) external returns (uint256 proposalId) {
        return
            _propose(
                msg.sender,
                description,
                betsClosedAt,
                readyForValidationAt
            );
    }

    function propose(
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 betsClosedAt,
        uint256 readyForValidationAt
    ) external payable returns (uint256 proposalId) {
        proposalId = _propose(
            msg.sender,
            description,
            betsClosedAt,
            readyForValidationAt
        );
        _placeBet(proposalId, msg.sender, bet, msg.value);

        return proposalId;
    }

    function placeBet(uint256 proposalId, string calldata bet)
        external
        payable
        returns (uint256 betId)
    {
        return _placeBet(proposalId, msg.sender, bet, msg.value);
    }

    function claimRewards() external {
        uint256 totalRewards = 0;
        uint256 numberOfBetsToClaim = betsToClaim[msg.sender].length();
        uint256[] memory betIds = new uint256[](numberOfBetsToClaim);

        for (uint256 i = 0; i < numberOfBetsToClaim; i++) {
            (uint256 betId, uint256 proposalId) = betsToClaim[msg.sender].at(i);

            totalRewards += bets.getProposal(proposalId).validated
                ? bets.calculateRewards(msg.sender, betId)
                : 0;

            betIds[i] = betId;
        }

        // todo: hmmm..
        for (uint256 i = 0; i < numberOfBetsToClaim; i++) {
            betsToClaim[msg.sender].remove(betIds[i]);
        }

        (bool success, ) = msg.sender.call{value: totalRewards}("");

        if (!success) {
            revert RewardsTransferUnsuccessful();
        }
    }

    function getActiveBets() external view returns (uint256[] memory betIds) {
        uint256 numberOfActiveBets = betsToClaim[msg.sender].length();

        betIds = new uint256[](numberOfActiveBets);

        for (uint256 i = 0; i < numberOfActiveBets; i++) {
            (uint256 betId, ) = betsToClaim[msg.sender].at(0);
            betIds[i] = betId;
        }

        return betIds;
    }

    function _propose(
        address creator,
        string memory description,
        uint256 betsClosedAt,
        uint256 readyForValidationAt
    ) internal ensureValidAddress(creator) returns (uint256 proposalId) {
        if (betsClosedAt > readyForValidationAt) {
            revert InvalidDates();
        }

        DABets.Proposal memory proposal;
        proposal.description = description;
        proposal.creator = msg.sender;
        proposal.betsClosedAt = betsClosedAt;
        proposal.readyForValidationAt = readyForValidationAt;

        proposalId = bets.addProposal(proposal);

        return proposalId;
    }

    function _placeBet(
        uint256 proposalId,
        address player,
        string calldata bet,
        uint256 stake
    )
        internal
        ensureValidAddress(player)
        ensureEnoughStake(stake)
        ensureBetsAreOpen(proposalId)
        returns (uint256 betId)
    {
        betId = bets.placeBet(proposalId, player, bet, stake);
        betsToClaim[player].set(betId, proposalId);
        return betId;
    }

    modifier ensureEnoughStake(uint256 stake) {
        if (stake < minStake) {
            revert InsufficientStake();
        }
        _;
    }

    modifier ensureValidAddress(address a) {
        if (a == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier ensureBetsAreOpen(uint256 proposalId) {
        if (block.timestamp > bets.getProposal(proposalId).betsClosedAt) {
            revert ClosedBets();
        }
        _;
    }

    modifier ensureProposalIsValidated(uint256 proposalId) {
        if (!bets.getProposal(proposalId).validated) {
            revert ProposalNotValidated();
        }
        _;
    }

    modifier ensureRewardsNotClaimed(uint256 proposalId) {
        /*
        if (claimed[proposalId][msg.sender]) {
            revert RewardsAlreadyClaimed();
        }
        */
        _;
    }
}
