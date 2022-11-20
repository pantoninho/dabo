// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FACT} from "./FACT.sol";
import "forge-std/console2.sol";

// TODO: is there some kind of standard for this type of contract? check ERC4646
/**
 * @author  0xerife
 * @title   DAIM Treasury
 * @notice  TODO: write this
 */
contract DAIMTreasury {
    FACT public fact;

    error PriceNotSet();
    error PriceAlreadySet();
    error PositiveAmount();

    event InitialTrade();

    bool private priceIsSet;

    constructor(uint256 maxSupply) {
        fact = new FACT(maxSupply, this);
    }

    receive() external payable {
        if (!priceIsSet) {
            revert PriceNotSet();
        }

        uint256 balanceBefore = address(this).balance - msg.value;
        console2.logUint(balanceBefore);

        fact.mint(msg.sender, (msg.value * fact.totalSupply()) / balanceBefore);
    }

    function initialTrade(uint256 amount) external payable {
        if (priceIsSet) {
            revert PriceAlreadySet();
        }

        if (amount == 0) {
            revert PositiveAmount();
        }

        fact.mint(msg.sender, amount);
        priceIsSet = true;
    }

    function isPriceSet() external view returns (bool) {
        return address(this).balance != 0;
    }

    function getFactPrice() external view returns (uint256) {
        if (!priceIsSet) {
            revert PriceNotSet();
        }

        return (address(this).balance * 1 ether) / fact.totalSupply();
    }
}
