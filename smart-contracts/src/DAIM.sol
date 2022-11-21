// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FACT} from "./FACT.sol";
import {DAIMarkets} from "./DAIMarkets.sol";
import {DAIOffice} from "./DAIOffice.sol";
import {DAIBookie} from "./DAIBookie.sol";
import {DAIMTreasury} from "./DAIMTreasury.sol";
import {FACTx} from "./FACTx.sol";
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
        treasury = new DAIMTreasury(20 ether);
        fact = treasury.fact();
        factx = new FACTx(fact);

        bets = new DAIMarkets(this);
        bookie = new DAIBookie(this);
        office = new DAIOffice(this);
    }
}
