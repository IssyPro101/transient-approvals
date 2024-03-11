// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {TransientERC20} from "../../src/tokens/TransientERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestTransientERC20 is TransientERC20 {
    constructor(uint256 _initialMint) TransientERC20("TestToken", "TT", 18) {
        _mint(msg.sender, _initialMint);
    }
}
