// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DABets.sol";
import "./Errors.sol";

import "forge-std/console2.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bookie
 * @notice  TODO: write this
 */
contract DABookie {
    DABets public bets;
    uint256 public constant minStake = 0.01 ether; // TODO: governance should be able to update this
    mapping(uint256 => uint256) betPools;
    mapping(uint256 => string[]) placedBets;
    mapping(uint256 => uint256) placedBetsStakes;
    mapping(address => mapping(uint256 => uint256)) playerStakes;

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
    {
        _placeBet(proposalId, msg.sender, bet, msg.value);
    }

    function claimRewards(uint256 id) external ensureBetIsValidated(id) {
        (bool success, ) = msg.sender.call{
            value: _calculateRewards(msg.sender, id)
        }("");

        if (!success) {
            revert RewardsTransferUnsuccessful();
        }
    }

    function getBetPool(uint256 proposalId)
        external
        view
        returns (uint256 stake)
    {
        return betPools[proposalId];
    }

    function getPlacedBetStake(uint256 proposalId, string calldata bet)
        external
        view
        returns (uint256 stake)
    {
        return placedBetsStakes[_placedBetId(proposalId, bet)];
    }

    function getPlayerStake(
        address player,
        uint256 proposalId,
        string calldata bet
    ) external view returns (uint256 stake) {
        return playerStakes[player][_placedBetId(proposalId, bet)];
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

        proposalId = bets.create(proposal);

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
    {
        // generate placed bet id to uniquely identify a placed bet inside a bet
        uint256 placedBetId = _placedBetId(proposalId, bet);
        // check if some already placed the exact same bet
        bool exists = placedBetsStakes[placedBetId] > 0;

        // if not, add it to list of placed bets for this bet
        if (!exists) {
            placedBets[proposalId].push(bet);
        }

        betPools[proposalId] += stake; // increment total stakes associated with this bet
        placedBetsStakes[placedBetId] += stake; // increment stakes associated with this placed bet
        playerStakes[player][placedBetId] += stake; // increment stakes of the player in this placed bet
    }

    function _calculateRewards(address player, uint256 proposalId)
        internal
        returns (uint256)
    {
        DABets.Proposal memory bet = bets.get(proposalId);
        uint256 totalStake = betPools[proposalId];
        uint256 totalWinningStake = 0;
        uint256 playerWinningStakes = 0;

        for (uint256 i = 0; i < bet.validBets.length; i++) {
            string memory validBet = bet.validBets[i];
            uint256 placedBetId = _placedBetId(proposalId, validBet);
            totalWinningStake += placedBetsStakes[placedBetId];
            playerWinningStakes += playerStakes[player][placedBetId];
            playerStakes[player][placedBetId] = 0;
        }

        uint256 winningShare = (totalStake * playerWinningStakes) /
            totalWinningStake;

        return winningShare;
    }

    function _placedBetId(uint256 proposalId, string memory bet)
        internal
        pure
        returns (uint256 id)
    {
        return uint256(keccak256(abi.encodePacked(proposalId, bet)));
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

    modifier ensureBetsAreOpen(uint256 id) {
        if (block.timestamp > bets.get(id).betsClosedAt) {
            revert ClosedBets();
        }
        _;
    }

    modifier ensureBetIsValidated(uint256 id) {
        if (!bets.get(id).validated) {
            revert BetNotValidated();
        }
        _;
    }
}
