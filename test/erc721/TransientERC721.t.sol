// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC721} from "./TestTransientERC721.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TransientERC721 is Test {
    TestTransientERC721 token;
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
        token = new TestTransientERC721();
        assertEq(token.balanceOf(OWNER), 1);
        vm.stopPrank();
    }

    function test_setAndLoadTransientERC721Approval() external {
        address approvedSpenderBefore = token.getTransientApproved(TOKEN_ID);
        assertEq(approvedSpenderBefore, address(0));

        vm.prank(OWNER);
        token.transientApprove(SPENDER, TOKEN_ID);

        address approvedSpenderAfter = token.getTransientApproved(TOKEN_ID);

        assertEq(approvedSpenderAfter, SPENDER);
    }

    function test_setAndLoadNormalERC721Approval() external {
        address approvedSpenderBefore = token.getApproved(TOKEN_ID);
        assertEq(approvedSpenderBefore, address(0));

        vm.prank(OWNER);
        token.approve(SPENDER, TOKEN_ID);

        address approvedSpenderAfter = token.getApproved(TOKEN_ID);

        assertEq(approvedSpenderAfter, SPENDER);
    }

    function test_setAndLoadTransientERC721ApprovalForAll() external {
        bool isApprovedBefore = token.isTransientApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);

        bool isApprovedAfter = token.isTransientApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_setAndLoadNormalERC721ApprovalForAll() external {
        bool isApprovedBefore = token.isApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        bool isApprovedAfter = token.isApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_setAndLoadTransientERC721ApprovalForAllAndApprovingTransient() external {
        bool isApprovedBefore = token.isTransientApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);
        
        vm.prank(SPENDER);
        token.transientApprove(SPENDER_TWO, TOKEN_ID);

        bool isApprovedAfter = token.isTransientApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_setAndLoadTransientERC721ApprovalForAllAndApprovingNormal() external {
        bool isApprovedBefore = token.isTransientApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);
        
        vm.prank(SPENDER);
        vm.expectRevert();
        token.approve(SPENDER_TWO, TOKEN_ID);

        bool isApprovedAfter = token.isTransientApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_setAndLoadNormalERC721ApprovalForAllAndApprovingNormal() external {
        bool isApprovedBefore = token.isApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        vm.prank(SPENDER);
        token.approve(SPENDER_TWO, TOKEN_ID);

        bool isApprovedAfter = token.isApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_setAndLoadNormalERC721ApprovalForAllAndApprovingTransient() external {
        bool isApprovedBefore = token.isApprovedForAll(OWNER, SPENDER);
        assertFalse(isApprovedBefore);

        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        vm.prank(SPENDER);
        token.transientApprove(SPENDER_TWO, TOKEN_ID);

        bool isApprovedAfter = token.isApprovedForAll(OWNER, SPENDER);

        assertTrue(isApprovedAfter);
    }

    function test_transientERC721TokenTransfer() external {
        vm.prank(OWNER);
        token.transientApprove(SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transientTransferFrom(OWNER, SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 1);
        assertEq(token.balanceOf(OWNER), 0);
    }

    function test_normalERC721TokenTransfer() external {
        vm.prank(OWNER);
        token.approve(SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 1);
        assertEq(token.balanceOf(OWNER), 0);
    }

    function test_transientERC721TokenTransferWithForAllApproval() external {
        vm.prank(OWNER);
        token.setTransientApprovalForAll(SPENDER, true);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transientTransferFrom(OWNER, SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 1);
        assertEq(token.balanceOf(OWNER), 0);
    }

    function test_normalERC721TokenTransferWithForAllApproval() external {
        vm.prank(OWNER);
        token.setApprovalForAll(SPENDER, true);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 1);
        assertEq(token.balanceOf(OWNER), 0);
    }
}
