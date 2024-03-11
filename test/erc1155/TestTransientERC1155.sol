// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {TransientERC1155} from "../../src/tokens/TransientERC1155.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestTransientERC1155 is TransientERC1155 {
    constructor() {
        _mint(msg.sender, 0, 1, "0x");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return "";
    }
}
