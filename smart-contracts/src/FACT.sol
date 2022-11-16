// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {DAIMTreasury} from "./DAIMTreasury.sol";

/**
 * @author  0xerife
 * @title   DAIM Token (FACT)
 * @notice  TODO: write this
 */
contract FACT is ERC20 {
    uint256 maxSupply;
    DAIMTreasury treasury;

    error MaxSupplyReached();
    error Unauthorized();

    /**
     * @notice  TODO: write this
     * @param   amount  amount to mint
     */
    modifier ensureAvailableSupply(uint256 amount) {
        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyReached();
        }
        _;
    }

    /**
     * @notice  TODO: write this
     */
    modifier onlyTreasury() {
        if (msg.sender != address(treasury)) {
            revert Unauthorized();
        }
        _;
    }

    constructor(uint256 _maxSupply, DAIMTreasury _treasury)
        ERC20("DAIM Tokens", "FACT")
    {
        maxSupply = _maxSupply;
        treasury = _treasury;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /**
     * @notice  mints FACT tokens to a target account. reverts if maxTotalSupply has been reached
     * @param   account  target account
     * @param   amount  amount of tokens to mint
     */
    function _mint(address account, uint256 amount)
        internal
        override
        onlyTreasury
        ensureAvailableSupply(amount)
    {
        ERC20._mint(account, amount);
    }
}
