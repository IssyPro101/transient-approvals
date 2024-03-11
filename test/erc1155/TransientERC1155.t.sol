// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC1155} from "./TestTransientERC1155.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TransientERC1155 is Test {
    TestTransientERC1155 token;
    address immutable OWNER;
    address immutable SPENDER;
    address immutable SPENDER_TWO;
    uint256 constant TOKEN_ID = 0;

    constructor() {
        OWNER= makeAddr("owner");
        SPENDER = makeAddr("spender");
        SPENDER = makeAddr("spenderTwo");
    }

    function setUp() external {
        vm.prank(OWNER);
        token = new TestTransientERC1155();
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 1);
        vm.stopPrank();
    }

    function test_setAndLoadTransientERC1155ApprovalForAll() external {
        bool isApprovedBefore = token.isTransientApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);

        bool isApprovedAfter = token.isTransientApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_setAndLoadNormalERC1155ApprovalForAll() external {
        bool isApprovedBefore = token.isApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        bool isApprovedAfter = token.isApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_transientERC1155TokenTransferWithForAllApproval() external {
        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 0);

        vm.prank(SPENDER);
        token.safeTransientTransferFrom(OWNER, SPENDER, TOKEN_ID, 1, "0x");

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 1);
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 0);
    }

    function test_normalERC1155TokenTransferWithForAllApproval() external {
        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 0);

        vm.prank(SPENDER);
        token.safeTransferFrom(OWNER, SPENDER, TOKEN_ID, 1, "0x");

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 1);
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 0);
    }

    function test_transientERC1155BatchTokenTransferWithForAllApproval() external {
        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 0);

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = TOKEN_ID;
        amounts[0] = 1;

        vm.prank(SPENDER);
        token.safeBatchTransientTransferFrom(OWNER, SPENDER, tokenIds, amounts, "0x");

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 1);
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 0);
    }

    function test_normalERC1155BatchTokenTransferWithForAllApproval() external {
        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 0);

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = TOKEN_ID;
        amounts[0] = 1;

        vm.prank(SPENDER);
        token.safeBatchTransferFrom(OWNER, SPENDER, tokenIds, amounts, "0x");

        assertEq(token.balanceOf(SPENDER, TOKEN_ID), 1);
        assertEq(token.balanceOf(OWNER, TOKEN_ID), 0);
    }
}
