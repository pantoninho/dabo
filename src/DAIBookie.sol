// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DAIM} from "./DAIM.sol";
import {DAIMarkets} from "./DAIMarkets.sol";
import {DAIOffice} from "./DAIOffice.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bookie
 * @notice  Creates betting proposals and places bets in the exchange for staking eth
 */
contract DAIBookie {
    DAIM public daim;

    uint256 public constant minStake = 0.01 ether; // TODO: governance should be able to update this
    // address => betId[]
    mapping(address => uint256[]) betsToClaim;

    constructor(DAIM _daim) {
        daim = _daim;
    }

    /**
     * @notice  Creates a betting proposal
     * @param   description the proposal itself. a string describing the subject of the bet
     * @param   betsClosedAt unix timestamp (in seconds) after which no more bets will be accepted
     * @param   readyForValidationAt timestamp (in seconds) after which the proposal may be validated
     */
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

    /**
     * @notice  Creates a betting proposal and places a bet on it
     * @param   description the proposal itself. a string describing the subject of the bet
     * @param   bet a bet to be placed on the created proposal
     * @param   betsClosedAt unix timestamp (in seconds) after which no more bets will be accepted
     * @param   readyForValidationAt timestamp (in seconds) after which the proposal may be validated
     * @return  proposalId the id of the proposal
     */
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
    }

    /**
     * @notice  Places a bet on an existing proposal
     * @param   proposalId  the proposal to bet on
     * @param   bet  the bet to be placed
     * @return  betId  the id of the placed bet
     */
    function placeBet(uint256 proposalId, string calldata bet)
        external
        payable
        returns (uint256 betId)
    {
        return _placeBet(proposalId, msg.sender, bet, msg.value);
    }

    /**
     * @notice  Claims rewards from validated proposals where caller's bets were placed
     */
    function claimRewards() external {
        uint256 totalRewards = 0;
        uint256[] memory claimables = betsToClaim[msg.sender];

        for (uint256 i = 0; i < claimables.length; i++) {
            uint256 betId = claimables[i];
            bool isWinner = office().isWinner(betId);
            totalRewards += isWinner
                ? bets().calculateRewards(msg.sender, betId)
                : 0;
        }

        delete betsToClaim[msg.sender]; // todo: is this ok?
        (bool success, ) = msg.sender.call{value: totalRewards}("");

        if (!success) {
            revert RewardsTransferUnsuccessful();
        }
    }

    /**
     * @notice  Gets all caller's bets that have not yet been claimed
     * @return  betIds  an array of bet ids
     */
    function getActiveBets() external view returns (uint256[] memory betIds) {
        uint256[] memory claimables = betsToClaim[msg.sender];
        betIds = new uint256[](claimables.length);

        for (uint256 i = 0; i < claimables.length; i++) {
            uint256 betId = betsToClaim[msg.sender][i];
            betIds[i] = betId;
        }

        return betIds;
    }

    function bets() internal view returns (DAIMarkets) {
        return daim.bets();
    }

    function office() internal view returns (DAIOffice) {
        return daim.office();
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

        DAIMarkets.Proposal memory proposal;
        proposal.description = description;
        proposal.creator = msg.sender;
        proposal.betsClosedAt = betsClosedAt;
        proposal.readyForValidationAt = readyForValidationAt;

        proposalId = bets().addProposal(proposal);

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
        betId = bets().placeBet(proposalId, player, bet, stake);
        betsToClaim[player].push(betId);
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
        if (block.timestamp > bets().getProposal(proposalId).betsClosedAt) {
            revert ClosedBets();
        }
        _;
    }

    modifier ensureProposalIsValidated(uint256 proposalId) {
        if (!bets().getProposal(proposalId).validated) {
            revert ProposalNotValidated();
        }
        _;
    }
}
