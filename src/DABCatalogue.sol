// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DABookie.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Bet Catalogue
 * @dev     .
 * @notice  .
 */

contract DABCatalogue {
    struct Bet {
        // TODO: better names for Bet / PlacedBet? looks confusing
        uint256 id;
        string description;
        address creator;
        uint256 placeBetDeadline;
        uint256 validationDate;
        string[] validBets;
        bool validated;
    }

    mapping(uint256 => Bet) bets;
    DABookie bookie;

    modifier onlyBookie() {
        if (msg.sender != address(bookie)) {
            revert Unauthorized();
        }
        _;
    }

    modifier ensureBetExists(uint256 id) {
        if (bets[id].creator == address(0)) {
            revert BetNotFound();
        }
        _;
    }

    constructor(DABookie _bookie) {
        bookie = _bookie;
    }

    function create(Bet memory bet) external onlyBookie returns (uint256 id) {
        id = uint256(keccak256(abi.encodePacked(bet.description, bet.creator)));

        bet.id = id;
        bets[id] = bet;

        return id;
    }

    function get(uint256 id)
        external
        view
        ensureBetExists(id)
        returns (Bet memory bet)
    {
        return bets[id];
    }
}
