// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20Test is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("ERC20Test", "ERCT") ERC20Permit("ERC20Test") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
