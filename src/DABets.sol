// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DABookie.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   Decentralized Autonomous Proposal Catalogue
 * @dev     .
 * @notice  .
 */

contract DABets {
    struct Proposal {
        uint256 id;
        string description;
        address creator;
        uint256 betsClosedAt;
        uint256 readyForValidationAt;
        string[] validBets;
        bool validated;
    }

    mapping(uint256 => Proposal) proposals;
    DABookie bookie;

    modifier onlyBookie() {
        if (msg.sender != address(bookie)) {
            revert Unauthorized();
        }
        _;
    }

    modifier ensureBetExists(uint256 id) {
        if (proposals[id].creator == address(0)) {
            revert BetNotFound();
        }
        _;
    }

    constructor(DABookie _bookie) {
        bookie = _bookie;
    }

    function create(Proposal memory proposal) external onlyBookie returns (uint256 id) {
        id = uint256(keccak256(abi.encodePacked(proposal.description, proposal.creator)));

        proposal.id = id;
        proposals[id] = proposal;

        return id;
    }

    function get(uint256 id)
        external
        view
        ensureBetExists(id)
        returns (Proposal memory proposal)
    {
        return proposals[id];
    }
}
