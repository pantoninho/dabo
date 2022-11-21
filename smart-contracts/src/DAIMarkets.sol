// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DAIM} from "./DAIM.sol";
import {DAIBookie} from "./DAIBookie.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bets
 * @dev     It should be noted that betId is the result of the hash over the bet and proposal id and does not include player data.
            This means that multiple players may have staked ether on the same bet of a proposal.
 * @notice  This smart contract manages proposals and their associated bets. Is also able to calculate the rewards of a bet.
 *          Write operations may only be called by the DAIBookie.
 */
contract DAIMarkets {
    struct Proposal {
        uint256 id;
        string description;
        string category;
        address creator;
        uint256 betsClosedAt;
        uint256 readyForValidationAt;
        uint256 betPool;
        uint256[] bets;
        bool validated;
    }

    DAIM daim;

    // [proposalId]
    uint256[] proposalIds;
    mapping(uint256 => Proposal) proposals;
    // betId => proposalId
    mapping(uint256 => uint256) betToProposal;
    // betId => staked amount
    mapping(uint256 => uint256) betStakes;
    // betId => string
    mapping(uint256 => string) betIdToString;
    // address => betId => stake
    mapping(address => mapping(uint256 => uint256)) playerStakes;

    constructor(DAIM _daim) {
        daim = _daim;
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
        proposalIds.push(proposalId);
    }

    function removeActiveProposal(uint256 id) external onlyOffice {
        uint256 index;
        bool found;
        for (uint256 i = 0; i < proposalIds.length; i++) {
            if (proposalIds[i] == id) {
                index = i;
                found = true;
            }
        }

        if (!found) {
            revert ProposalNotFound();
        }

        proposalIds[index] = proposalIds[proposalIds.length - 1];
        proposalIds.pop();
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
        ensureStake(stake)
        ensureProposalExists(proposalId)
        returns (uint256 betId)
    {
        betId = _placedBetId(proposalId, bet);

        // bet does not exist yet, add it to proposal bets array
        // and link their ids in betToProposal
        if (betStakes[betId] == 0) {
            proposals[proposalId].bets.push(betId);
            betToProposal[betId] = proposalId;
            betIdToString[betId] = bet;
        }

        // increment player staked amount on this bet
        playerStakes[player][betId] += stake;

        // increment bet staked amount
        betStakes[betId] += stake;

        // increment proposal bet pool
        proposals[proposalId].betPool += stake;
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
     * @notice  Gets a proposal associated with a betid
     * @param   betId  the betId id
     * @return  proposal  the proposal
     */
    function getProposalByBetId(uint256 betId)
        external
        view
        ensureBetExists(betId)
        returns (Proposal memory proposal)
    {
        return proposals[betToProposal[betId]];
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

    function getBetDescription(uint256 betId)
        external
        view
        ensureBetExists(betId)
        returns (string memory description)
    {
        return betIdToString[betId];
    }

    /**
     * @notice  Calculates a player's current potential rewards on a placed bet
     * @dev     This may be called while the bet is still ongoing. It calculates the rewards if the player's bet was a winner.
     * @param   player  the player address
     * @param   betId  the bet id
     * @return  rewards  the reward
     */
    function calculatePlayerRewards(address player, uint256 betId)
        external
        view
        ensureBetExists(betId)
        returns (uint256 rewards)
    {
        uint256 proposalId = betToProposal[betId];
        DAIMarkets.Proposal memory proposal = proposals[proposalId];

        uint256 totalStake = proposal.betPool;
        uint256 betStake = betStakes[betId];
        uint256 playerStake = playerStakes[player][betId];
        rewards = (totalStake * playerStake) / betStake;
    }

    /**
     * @notice  Calculates a potential rewards on a placed bet
     * @dev     This may be called while the bet is still ongoing. It calculates the rewards if the player's bet was a winner.
     * @param   amount  amount staked
     * @param   betId  the bet id
     * @return  rewards  the reward
     */
    function calculateRewards(uint256 amount, uint256 betId)
        external
        view
        ensureBetExists(betId)
        returns (uint256 rewards)
    {
        uint256 proposalId = betToProposal[betId];
        DAIMarkets.Proposal memory proposal = proposals[proposalId];

        uint256 totalStake = proposal.betPool;
        uint256 betStake = betStakes[betId];
        rewards = (totalStake * amount) / betStake;
    }

    function getNumberOfProposals() external view returns (uint256) {
        return proposalIds.length;
    }

    function getActiveProposals()
        external
        view
        returns (Proposal[] memory activeProposals)
    {
        activeProposals = new Proposal[](proposalIds.length);
        Proposal memory proposal;
        uint256 counter;

        for (uint256 i = 0; i < proposalIds.length; i++) {
            proposal = proposals[proposalIds[i]];

            activeProposals[counter] = proposal;
            counter++;
        }
    }

    function getActiveProposalIds() external view returns (uint256[] memory) {
        return proposalIds;
    }

    function _placedBetId(uint256 proposalId, string memory bet)
        internal
        pure
        returns (uint256 betId)
    {
        return uint256(keccak256(abi.encode(proposalId, bet)));
    }

    modifier onlyBookie() {
        if (msg.sender != address(daim.bookie())) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOffice() {
        if (msg.sender != address(daim.office())) {
            revert Unauthorized();
        }
        _;
    }

    modifier ensureProposalExists(uint256 id) {
        if (proposals[id].id == 0) {
            revert ProposalNotFound();
        }
        _;
    }

    modifier ensureBetExists(uint256 id) {
        if (betToProposal[id] == 0) {
            revert BetNotFound();
        }
        _;
    }

    modifier ensureStake(uint256 stake) {
        if (stake == 0) {
            revert InsufficientStake();
        }
        _;
    }
}
