// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC20} from "../../erc20/TestTransientERC20.sol";
import {LibString} from "../../../lib/solady/src/utils/LibString.sol";
import {SafeTransientTransferLib} from "../../../src/utils/SafeTransientTransferLib.sol";

contract SafeTransientTransferLibRestrictions is Test {
    using SafeTransientTransferLib for TestTransientERC20;
    TestTransientERC20 token;
    address immutable OWNER;
    address immutable SPENDER;
    uint256 constant INITIAL_MINT = 1000 ether;
    uint256 constant TEST_APPROVAL_AMOUNT = 100;

    constructor() {
        OWNER = makeAddr("owner");
        SPENDER = makeAddr("spender");
    }

    function setUp() external {
        vm.prank(OWNER);
        token = new TestTransientERC20(INITIAL_MINT);
        assertEq(token.balanceOf(OWNER), 1000 ether);
        vm.stopPrank();

        vm.startPrank(OWNER);
        token.safeTransientApprove(SPENDER, TEST_APPROVAL_AMOUNT);
        token.safeApprove(SPENDER, TEST_APPROVAL_AMOUNT);
        vm.stopPrank();

        uint256 transientApproval = token.transientAllowance(OWNER, SPENDER);
        uint256 normalApproval = token.transientAllowance(OWNER, SPENDER);

        assertEq(transientApproval, TEST_APPROVAL_AMOUNT);
        assertEq(normalApproval, TEST_APPROVAL_AMOUNT);
    }

    function test_cantSafelyTransferERC20TokensTransientlyWithSafeApproval() external {
        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        vm.expectRevert();
        vm.expectRevert();
        token.safeTransientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        vm.prank(SPENDER);
        token.safeTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }
}
