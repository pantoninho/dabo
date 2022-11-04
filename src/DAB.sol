// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/token/ERC20/ERC20.sol";
import "./DABOTreasury.sol";

/**
 * @author  0xerife
 * @title   DABO Token (DAB)
 * @notice  TODO: write this
 */
contract DAB is ERC20 {
    uint256 maxSupply;
    DABOTreasury treasury;

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

    constructor(uint256 _maxSupply, DABOTreasury _treasury)
        ERC20("DABO Tokens", "DAB")
    {
        maxSupply = _maxSupply;
        treasury = _treasury;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /**
     * @notice  mints DAB tokens to a target account. reverts if maxTotalSupply has been reached
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
