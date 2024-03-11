// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC1155} from "../TestTransientERC1155.sol";
import {LibString} from "../../../lib/solady/src/utils/LibString.sol";

contract TransientERC1155RestrictionsForAll is Test {
    TestTransientERC1155 token;
    address immutable OWNER;
    address immutable SPENDER;
    uint256 constant TOKEN_ID = 0;

    constructor() {
        OWNER = makeAddr("owner");
        SPENDER = makeAddr("spender");
    }

    function setUp() external {

        vm.prank(OWNER);
        token = new TestTransientERC1155();
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 1);
        vm.stopPrank();

        bool isTransientApprovedForAllBefore = token.isTransientApprovedForAll(OWNER, SPENDER);
        bool isApprovedForAllBefore = token.isApprovedForAll(OWNER, SPENDER);
        assertFalse(isTransientApprovedForAllBefore);
        assertFalse(isApprovedForAllBefore);

        vm.startPrank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);
        token.setApprovalForAll(SPENDER, true);
        vm.stopPrank();

        bool isTransientApprovedForAllAfter = token.isTransientApprovedForAll(OWNER, SPENDER);
        bool isApprovedForAllAfter = token.isApprovedForAll(OWNER, SPENDER);
        assertTrue(isTransientApprovedForAllAfter);
        assertTrue(isApprovedForAllAfter);
        
    }

    function test_cantTransferERC1155TokensTransientlyWithForAllApproval() external {
        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 0);

        vm.prank(SPENDER);
        vm.expectRevert();
        token.safeTransientTransferFrom(OWNER, SPENDER, TOKEN_ID, 1, "0x");

        vm.prank(SPENDER);
        token.safeTransferFrom(OWNER, SPENDER, TOKEN_ID, 1, "0x");

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 1);
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 0);
    }

    function test_cantBatchTransferERC1155TokensTransientlyWithForAllApproval() external {
        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 0);

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = TOKEN_ID;
        amounts[0] = 1;

        vm.prank(SPENDER);
        vm.expectRevert();
        token.safeBatchTransientTransferFrom(OWNER, SPENDER, tokenIds, amounts, "0x");

        vm.prank(SPENDER);
        token.safeBatchTransferFrom(OWNER, SPENDER, tokenIds, amounts, "0x");

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 1);
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 0);
    }
}
