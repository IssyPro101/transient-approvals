// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC20} from "../erc20/TestTransientERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SafeTransientTransferLib} from "../../../src/utils/SafeTransientTransferLib.sol";

contract TransientERC20 is Test {
    using SafeTransientTransferLib for TestTransientERC20;
    TestTransientERC20 token;
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant TRANSIENT_PERMIT_TYPEHASH =
        keccak256(
            "TransientPermit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    address immutable OWNER;
    uint256 immutable OWNER_PK;
    address immutable SPENDER;
    uint256 constant INITIAL_MINT = 1000 ether;
    uint256 constant TEST_APPROVAL_AMOUNT = 100;

    constructor() {
        (OWNER, OWNER_PK) = makeAddrAndKey("owner");
        SPENDER = makeAddr("spender");
    }

    function setUp() external {
        vm.prank(OWNER);
        token = new TestTransientERC20(INITIAL_MINT);
        assertEq(token.balanceOf(OWNER), 1000 ether);
        vm.stopPrank();
    }

    function test_setAndLoadSafeTransientERC20Approval() external {
        uint256 approvalBefore = token.transientAllowance(OWNER, SPENDER);
        assertEq(approvalBefore, 0);

        vm.prank(OWNER);
        token.safeTransientApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        uint256 approvalAfter = token.transientAllowance(OWNER, SPENDER);

        assertEq(approvalAfter, TEST_APPROVAL_AMOUNT);
    }

    function test_setAndLoadSafeNormalERC20Approval() external {
        uint256 approvalBefore = token.transientAllowance(OWNER, SPENDER);
        assertEq(approvalBefore, 0);

        vm.prank(OWNER);
        token.safeApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        uint256 approvalAfter = token.allowance(OWNER, SPENDER);

        assertEq(approvalAfter, TEST_APPROVAL_AMOUNT);
    }

    function test_safeTransientERC20TokenApprovalAndTransfer() external {
        vm.prank(OWNER);
        token.safeTransientApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.safeTransientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_safeTransientERC20TokenApprovalAndUnsafeTransfer() external {
        vm.prank(OWNER);
        token.safeTransientApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_unsafeTransientERC20TokenApprovalAndSafeTransfer() external {
        vm.prank(OWNER);
        token.transientApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.safeTransientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_safeNormalERC20TokenTransferAndTransfer() external {
        vm.prank(OWNER);
        token.safeApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.safeTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_safeNormalERC20TokenTransferAndUnsafeTransfer() external {
        vm.prank(OWNER);
        token.safeApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_unsafeNormalERC20TokenTransferAndSafeTransfer() external {
        vm.prank(OWNER);
        token.approve(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.safeTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }
}
