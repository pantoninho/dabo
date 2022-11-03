// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author  @xerife
 * @title   DABO Bets
 * @notice  TODO: write this
 */
contract DABOBets {
    enum BetState {
        NOT_CREATED,
        ACTIVE,
        CLOSED
    }

    struct PlacedBet {
        address better;
        uint256 staked;
    }

    struct Bet {
        // TODO: better names for Bet / PlacedBet? looks confusing
        uint256 id;
        string description;
        address creator;
        uint256 placeBetDeadline;
        uint256 validationDate;
        uint256 value;
        mapping(string => PlacedBet[]) placedBets;
    }

    mapping(uint256 => Bet) betsById;
    uint256 public constant minStake = 0.01 ether; // TODO: governance should be able to update this

    error ClosedBets();
    error InsufficientStake();
    error InvalidDates();

    modifier ensureEnoughStake() {
        if (msg.value < minStake) {
            revert InsufficientStake();
        }
        _;
    }

    function create(
        string calldata description, // TODO: calldata or memory?
        string calldata bet,
        uint256 placeBetDeadline,
        uint256 validationDate
    ) external payable ensureEnoughStake returns (uint256) {
        if (placeBetDeadline > validationDate) {
            revert InvalidDates();
        }

        uint256 id = uint256(
            keccak256(abi.encodePacked(description, msg.sender, bet))
        );

        betsById[id].id = id;
        betsById[id].description = description;
        betsById[id].creator = msg.sender;
        betsById[id].placeBetDeadline = placeBetDeadline;
        betsById[id].validationDate = validationDate;
        betsById[id].value = msg.value;

        PlacedBet memory placedBet = PlacedBet({
            better: msg.sender,
            staked: msg.value
        });

        betsById[id].placedBets[bet].push(placedBet);

        return id;
    }
}
