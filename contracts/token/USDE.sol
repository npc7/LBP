// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDE is ERC20 {
    constructor() ERC20("USDE", "USDE") {
        _mint(msg.sender, 3000000000 * 10 ** 18);
    }
}