// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/console2.sol";

import "./FACT.sol";
import "./DAIMarkets.sol";
import "./DAIOffice.sol";
import "./DAIBookie.sol";
import "./DAIMTreasury.sol";
import "./FACTx.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   DAIM
 * @notice  TODO: write this
 */
contract DAIM {
    DAIMTreasury public treasury;
    FACT public fact;
    FACTx public factx;
    DAIBookie public bookie;
    DAIOffice public office;
    DAIMarkets public bets;

    constructor() {
        treasury = new DAIMTreasury();
        fact = new FACT(1000, treasury);
        factx = new FACTx(fact);

        bets = new DAIMarkets(this);
        bookie = new DAIBookie(this);
        office = new DAIOffice(this);
    }
}
