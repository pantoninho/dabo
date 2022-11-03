// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DAB.sol";

// TODO: is there some kind of standard for this type of contract? check ERC4646
/**
 * @author  @xerife
 * @title   DABO Treasury
 * @notice  TODO: write this
 */
contract DABOTreasury {
    DAB public dab;

    constructor(uint256 initialMaxSupply) {
        // TODO: test if is an instance of DAB?
        dab = new DAB(initialMaxSupply, this);
    }
}
