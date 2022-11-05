// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DABookie.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bets
 * @dev     It should be noted that betId is the result of the hash over the bet and proposal id and does not include player data.
            This means that multiple players may have staked ether on the same bet of a proposal.
 * @notice  This smart contract manages proposals and their associated bets. Is also able to calculate the rewards of a bet.
 *          Write operations may only be called by the DABookie.
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

    /**
     * @notice  Adds a betting proposal. May only be called by the bookie
     * @param   proposal the proposal
     * @return  proposalId  the proposal id
     */
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

    /**
     * @notice  Adds a bet and its stake to a proposal
     * @param   proposalId  the proposal id
     * @param   player  who's betting
     * @param   bet  the bet
     * @param   stake  staked ether
     * @return  betId  the bet id
     */
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

    /**
     * @notice  Gets a proposal by its id
     * @param   proposalId  the proposal id
     * @return  proposal  the proposal
     */
    function getProposal(uint256 proposalId)
        external
        view
        ensureProposalExists(proposalId)
        returns (Proposal memory proposal)
    {
        return proposals[proposalId];
    }

    /**
     * @notice  Gets a bet's staked ether amount
     * @param   betId  the bet id
     * @return  stake  the amount of staked ether
     */
    function getStakeOnBet(uint256 betId)
        external
        view
        returns (uint256 stake)
    {
        return betStakes[betId];
    }

    /**
     * @notice  Gets a player's stake on a bet
     * @param   player  the player address
     * @param   betId  the bet id
     * @return  stake  the amount of staked ether
     */
    function getPlayerStakeOnBet(address player, uint256 betId)
        external
        view
        returns (uint256 stake)
    {
        return playerStakes[player][betId];
    }

    /**
     * @notice  Calculates a player's rewards on a placed bet
     * @param   player  the player address
     * @param   betId  the bet id
     * @return  rewards  the reward
     */
    function calculateRewards(address player, uint256 betId)
        public
        view
        returns (uint256 rewards)
    {
        uint256 proposalId = validBets[betId];

        if (proposalId == 0) {
            return 0;
        }

        DABets.Proposal memory proposal = proposals[proposalId];

        uint256 totalStake = proposal.betPool;
        uint256 betStake = betStakes[betId];
        uint256 playerStake = playerStakes[player][betId];
        rewards = (totalStake * playerStake) / betStake;
    }

    /**
     * @notice  Checks if this bet won it's proposal
     * @param   betId  the bet id
     * @return  winner  boolean indicating if this bet gets rewards
     */
    function isWinner(uint256 betId) public view returns (bool winner) {
        return validBets[betId] != 0;
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
