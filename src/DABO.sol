// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/console2.sol";

import "./DAB.sol";
import "./DABets.sol";
import "./DABOffice.sol";
import "./DABookie.sol";
import "./DABOTreasury.sol";
import "./DABV.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   DABO
 * @notice  TODO: write this
 */
contract DABO {
    DABOTreasury public treasury;
    DAB public dab;
    DABV public dabv;
    DABookie public bookie;
    DABOffice public office;
    DABets public bets;

    constructor() {
        treasury = new DABOTreasury();
        dab = new DAB(1000, treasury);
        dabv = new DABV(dab);

        bets = new DABets(this);
        bookie = new DABookie(this);
        office = new DABOffice(this);
    }
}
