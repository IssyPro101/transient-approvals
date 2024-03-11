// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC721} from "../TestTransientERC721.sol";
import {LibString} from "../../../lib/solady/src/utils/LibString.sol";

contract TransientERC721Restrictions is Test {
    TestTransientERC721 token;
    address immutable OWNER;
    address immutable SPENDER;
    uint256 constant INITIAL_MINT = 1000 ether;
    uint256 constant TEST_APPROVAL_AMOUNT = 100;
    uint256 constant TOKEN_ID = 0;

    constructor() {
        OWNER = makeAddr("owner");
        SPENDER = makeAddr("spender");
    }

    function setUp() external {

        vm.prank(OWNER);
        token = new TestTransientERC721();
        assertEq(token.balanceOf(OWNER), 1);
        vm.stopPrank();

        address approvedSpenderBefore = token.getApproved(TOKEN_ID);
        address approvedTransientSpenderBefore = token.getApproved(TOKEN_ID);
        assertEq(approvedSpenderBefore, address(0));
        assertEq(approvedTransientSpenderBefore, address(0));

        vm.startPrank(OWNER);
        token.transientApprove(SPENDER, TOKEN_ID);
        token.approve(SPENDER, TOKEN_ID);
        vm.stopPrank();

        address approvedSpenderAfter = token.getApproved(TOKEN_ID);
        address approvedTransientSpenderAfter = token.getApproved(TOKEN_ID);

        assertEq(approvedSpenderAfter, SPENDER);
        assertEq(approvedTransientSpenderAfter, SPENDER);
        
    }

    function test_cantTransferERC721TokensTransiently() external {
        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        vm.expectRevert();
        token.transientTransferFrom(OWNER, SPENDER, TOKEN_ID);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TOKEN_ID);

        assertEq(token.balanceOf(SPENDER), 1);
        assertEq(token.balanceOf(OWNER), 0);
    }
}
