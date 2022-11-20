// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console2.sol";

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {DAIMTreasury} from "./DAIMTreasury.sol";

/**
 * @author  0xerife
 * @title   DAIM Token (FACT)
 * @notice  TODO: write this
 */
contract FACT is ERC20 {
    uint256 public maxSupply;
    DAIMTreasury treasury;

    error MaxSupplyReached();
    error Unauthorized();

    constructor(uint256 _maxSupply, DAIMTreasury _treasury)
        ERC20("DAIM Tokens", "FACT")
    {
        maxSupply = _maxSupply;
        treasury = _treasury;
    }

    function mint(address account, uint256 amount) external onlyTreasury {
        _mint(account, amount);
    }

    /**
     * @notice  mints FACT tokens to a target account. reverts if maxTotalSupply has been reached
     * @param   account  target account
     * @param   amount  amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override {
        ERC20._mint(account, amount);
    }

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
}
