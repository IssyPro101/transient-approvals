// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC20} from "./TestTransientERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TransientERC20 is Test {
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

    function test_setAndLoadTransientERC20Approval() external {
        uint256 approvalBefore = token.transientAllowance(OWNER, SPENDER);
        assertEq(approvalBefore, 0);

        vm.prank(OWNER);
        token.transientApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        uint256 approvalAfter = token.transientAllowance(OWNER, SPENDER);

        assertEq(approvalAfter, TEST_APPROVAL_AMOUNT);
    }

    function test_setAndLoadNormalERC20Approval() external {
        uint256 approvalBefore = token.allowance(OWNER, SPENDER);
        assertEq(approvalBefore, 0);

        vm.prank(OWNER);
        token.approve(SPENDER, TEST_APPROVAL_AMOUNT);

        uint256 approvalAfter = token.allowance(OWNER, SPENDER);

        assertEq(approvalAfter, TEST_APPROVAL_AMOUNT);
    }

    function test_transientERC20TokenTransfer() external {
        vm.prank(OWNER);
        token.transientApprove(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_normalERC20TokenTransfer() external {
        vm.prank(OWNER);
        token.approve(SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_setAndLoadTransientERC20ApprovalWithPermit() external {
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSIENT_PERMIT_TYPEHASH,
                OWNER,
                SPENDER,
                TEST_APPROVAL_AMOUNT,
                0,
                block.timestamp
            )
        );

        bytes32 hash = MessageHashUtils.toTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            structHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PK, hash);

        uint256 approvalBefore = token.transientAllowance(OWNER, SPENDER);
        assertEq(approvalBefore, 0);


        uint256 noncesBefore = token.nonces(OWNER);
        assertEq(noncesBefore, 0);

        vm.prank(OWNER);
        token.transientPermit(
            OWNER,
            SPENDER,
            TEST_APPROVAL_AMOUNT,
            block.timestamp,
            v,
            r,
            s
        );
        uint256 noncesAfter = token.nonces(OWNER);
        assertEq(noncesAfter, 1);

        uint256 approvalAfter = token.transientAllowance(OWNER, SPENDER);
        assertEq(approvalAfter, TEST_APPROVAL_AMOUNT);
    }

    function test_setAndLoadNormalERC20ApprovalWithPermit() external {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                OWNER,
                SPENDER,
                TEST_APPROVAL_AMOUNT,
                0,
                block.timestamp
            )
        );

        bytes32 hash = MessageHashUtils.toTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            structHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PK, hash);

        uint256 approvalBefore = token.allowance(OWNER, SPENDER);
        assertEq(approvalBefore, 0);


        uint256 noncesBefore = token.nonces(OWNER);
        assertEq(noncesBefore, 0);

        vm.prank(OWNER);
        token.permit(
            OWNER,
            SPENDER,
            TEST_APPROVAL_AMOUNT,
            block.timestamp,
            v,
            r,
            s
        );
        uint256 noncesAfter = token.nonces(OWNER);
        assertEq(noncesAfter, 1);

        uint256 approvalAfter = token.allowance(OWNER, SPENDER);
        assertEq(approvalAfter, TEST_APPROVAL_AMOUNT);
    }

    function test_transientERC20TokenTransferWithPermit() external {

        bytes32 structHash = keccak256(
            abi.encode(
                TRANSIENT_PERMIT_TYPEHASH,
                OWNER,
                SPENDER,
                TEST_APPROVAL_AMOUNT,
                0,
                block.timestamp
            )
        );

        bytes32 hash = MessageHashUtils.toTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            structHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PK, hash);

        token.transientPermit(
            OWNER,
            SPENDER,
            TEST_APPROVAL_AMOUNT,
            block.timestamp,
            v,
            r,
            s
        );

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }

    function test_normalERC20TokenTransferWithPermit() external {

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                OWNER,
                SPENDER,
                TEST_APPROVAL_AMOUNT,
                0,
                block.timestamp
            )
        );

        bytes32 hash = MessageHashUtils.toTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            structHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PK, hash);

        token.permit(
            OWNER,
            SPENDER,
            TEST_APPROVAL_AMOUNT,
            block.timestamp,
            v,
            r,
            s
        );

        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }
}
