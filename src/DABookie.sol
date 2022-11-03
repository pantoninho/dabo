// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DABCatalogue.sol";
import "./Errors.sol";

import "forge-std/console2.sol";

/**
 * @author  @xerife
 * @title   Decentralized Autonomous Bookie
 * @notice  TODO: write this
 */
contract DABookie {
    DABCatalogue public bets;
    uint256 public constant minStake = 0.01 ether; // TODO: governance should be able to update this
    mapping(uint256 => uint256) betStakes;
    mapping(uint256 => string[]) placedBets;
    mapping(uint256 => uint256) placedBetsStakes;
    mapping(address => mapping(uint256 => uint256)) playerStakes;

    constructor() {
        bets = new DABCatalogue(this);
    }

    function create(
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate
    )
        external
        payable
        ensureValidAddress(msg.sender)
        ensureEnoughStake
        returns (uint256 betId)
    {
        if (placeBetDeadline > validationDate) {
            revert InvalidDates();
        }

        DABCatalogue.Bet memory _bet;
        _bet.description = description;
        _bet.creator = msg.sender;
        _bet.placeBetDeadline = placeBetDeadline;
        _bet.validationDate = validationDate;

        betId = bets.create(_bet);
        _placeBet(betId, bet);

        return betId;
    }

    function placeBet(uint256 id, string calldata bet)
        external
        payable
        ensureValidAddress(msg.sender)
        ensureBetsAreOpen(id)
        ensureEnoughStake
    {
        _placeBet(id, bet);
    }

    function claimPrize(uint256 id) external ensureBetIsValidated(id) {
        DABCatalogue.Bet memory bet = bets.get(id);
        uint256 totalStake = betStakes[id];
        uint256 totalWinningStake = 0;
        uint256 playerWinningStakes = 0;

        for (uint256 i = 0; i < bet.validBets.length; i++) {
            string memory validBet = bet.validBets[i];
            uint256 placedBetId = _placedBetId(id, validBet);
            totalWinningStake += placedBetsStakes[placedBetId];
            playerWinningStakes += playerStakes[msg.sender][placedBetId];
            playerStakes[msg.sender][placedBetId] = 0;
        }

        uint256 winningShare = (totalStake * playerWinningStakes) /
            totalWinningStake;

        (bool success, ) = msg.sender.call{value: winningShare}("");

        if (!success) {
            revert PrizeTransferUnsuccessful();
        }
    }

    function getBetStake(uint256 betId) external view returns (uint256 stake) {
        return betStakes[betId];
    }

    function getPlacedBetStake(uint256 betId, string calldata bet)
        external
        view
        returns (uint256 stake)
    {
        return placedBetsStakes[_placedBetId(betId, bet)];
    }

    function getPlayerStake(
        address player,
        uint256 betId,
        string calldata bet
    ) external view returns (uint256 stake) {
        return playerStakes[player][_placedBetId(betId, bet)];
    }

    function _placeBet(uint256 betId, string calldata bet) internal {
        // generate placed bet id to uniquely identify a placed bet inside a bet
        uint256 placedBetId = _placedBetId(betId, bet);
        // check if some already placed the exact same bet
        bool exists = placedBetsStakes[placedBetId] > 0;

        // if not, add it to list of placed bets for this bet
        if (!exists) {
            placedBets[betId].push(bet);
        }

        betStakes[betId] += msg.value; // increment total stakes associated with this bet
        placedBetsStakes[placedBetId] += msg.value; // increment stakes associated with this placed bet
        playerStakes[msg.sender][placedBetId] += msg.value; // increment stakes of the player in this placed bet
    }

    function _placedBetId(uint256 betId, string memory bet)
        internal
        pure
        returns (uint256 id)
    {
        return uint256(keccak256(abi.encodePacked(betId, bet)));
    }

    modifier ensureEnoughStake() {
        if (msg.value < minStake) {
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
        if (block.timestamp > bets.get(id).placeBetDeadline) {
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
