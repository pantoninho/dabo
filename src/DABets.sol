// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DABookie.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bets
 * @dev     .
 * @notice  This smart contract manages proposals and their associated bets
 */

contract DABets {
    struct Proposal {
        uint256 id;
        string description;
        address creator;
        uint256 betsClosedAt;
        uint256 readyForValidationAt;
        uint256 betPool;
        string[] bets;
        bool validated;
    }

    DABookie bookie;
    mapping(uint256 => Proposal) proposals;
    // betId => staked amount
    mapping(uint256 => uint256) betStakes;
    // address => betId => stake
    mapping(address => mapping(uint256 => uint256)) playerStakes;
    // betId => proposalId
    mapping(uint256 => uint256) validBets;

    constructor(DABookie _bookie) {
        bookie = _bookie;
    }

    function addProposal(Proposal memory proposal)
        external
        onlyBookie
        returns (uint256 proposalId)
    {
        proposalId = uint256(
            keccak256(abi.encodePacked(proposal.description, proposal.creator))
        );

        proposal.id = proposalId;
        proposals[proposalId] = proposal;

        return proposalId;
    }

    function placeBet(
        uint256 proposalId,
        address player,
        string memory bet,
        uint256 stake
    )
        external
        onlyBookie
        ensureProposalExists(proposalId)
        returns (uint256 betId)
    {
        betId = _placedBetId(proposalId, bet);

        // bet does not exist yet, add it to proposal bets array
        if (betStakes[betId] == 0) {
            proposals[proposalId].bets.push(bet);
        }

        // increment player staked amount on this bet
        playerStakes[player][betId] += stake;

        // increment bet staked amount
        betStakes[betId] += stake;

        // increment proposal bet pool
        proposals[proposalId].betPool += stake;

        return betId;
    }

    function getProposal(uint256 proposalId)
        external
        view
        ensureProposalExists(proposalId)
        returns (Proposal memory proposal)
    {
        return proposals[proposalId];
    }

    function getStakeOnBet(uint256 betId)
        external
        view
        returns (uint256 stake)
    {
        return betStakes[betId];
    }

    function getPlayerStakeOnBet(address player, uint256 betId)
        external
        view
        returns (uint256 stake)
    {
        return playerStakes[player][betId];
    }

    function calculateRewards(address player, uint256 betId)
        public
        view
        returns (uint256)
    {
        uint256 proposalId = validBets[betId];

        if (proposalId == 0) {
            return 0;
        }

        DABets.Proposal memory proposal = proposals[proposalId];

        uint256 totalStake = proposal.betPool;
        uint256 betStake = betStakes[betId];
        uint256 playerStake = playerStakes[player][betId];
        uint256 winningShare = (totalStake * playerStake) / betStake;

        return winningShare;
    }

    function _placedBetId(uint256 proposalId, string memory bet)
        internal
        pure
        returns (uint256 betId)
    {
        return uint256(keccak256(abi.encode(proposalId, bet)));
    }

    modifier onlyBookie() {
        if (msg.sender != address(bookie)) {
            revert Unauthorized();
        }
        _;
    }

    modifier ensureProposalExists(uint256 id) {
        if (proposals[id].creator == address(0)) {
            revert ProposalNotFound();
        }
        _;
    }
}
