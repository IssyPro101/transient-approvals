// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {TransientERC721} from "../../src/tokens/TransientERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestTransientERC721 is TransientERC721 {
    constructor() TransientERC721("TestToken", "TT") {
        _mint(msg.sender, 0);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}
