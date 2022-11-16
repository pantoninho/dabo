// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import {ERC4626} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract FACTx is ERC4626, ERC20Permit, ERC20Votes {
    address[] owners;

    constructor(IERC20 asset)
        ERC20("DAIM FACT Checker", "FACTx")
        ERC20Permit("DAIM FACT Checker")
        ERC4626(asset)
    {}

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function decimals()
        public
        view
        virtual
        override(ERC20, ERC4626)
        returns (uint8)
    {
        return ERC4626.decimals();
    }

    // The functions below are overrides required by Solidity.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        if (balanceOf(to) == 0) {
            owners.push(to);
        }

        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);

        if (balanceOf(account) == 0) {
            _removeOwner(account);
        }
    }

    function _removeOwner(address account) internal {
        uint256 index = 0;

        while (owners[index] != account) {
            index++;

            // index is out of bounds meaning account is not in the array.
            // abort
            if (index == owners.length) {
                return;
            }
        }

        // copy last item into index to be removed
        owners[index] = owners[owners.length - 1];

        // and pop last item
        owners.pop();
    }
}
