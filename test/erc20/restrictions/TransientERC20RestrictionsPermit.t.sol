// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientERC20} from "../TestTransientERC20.sol";
import {LibString} from "../../../lib/solady/src/utils/LibString.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TransientERC20RestrictionsPermit is Test {
    TestTransientERC20 token;
    address immutable OWNER;
    uint256 immutable OWNER_PK;
    address immutable SPENDER;
    uint256 constant INITIAL_MINT = 1000 ether;
    uint256 constant TEST_APPROVAL_AMOUNT = 100;
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    bytes32 private constant TRANSIENT_PERMIT_TYPEHASH =
        keccak256(
            "TransientPermit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    constructor() {
        (OWNER, OWNER_PK) = makeAddrAndKey("owner");
        SPENDER = makeAddr("spender");
    }

    function setUp() external {
        vm.prank(OWNER);
        token = new TestTransientERC20(INITIAL_MINT);
        assertEq(token.balanceOf(OWNER), 1000 ether);
        vm.stopPrank();

        bytes32 transientStructHash = keccak256(
            abi.encode(
                TRANSIENT_PERMIT_TYPEHASH,
                OWNER,
                SPENDER,
                TEST_APPROVAL_AMOUNT,
                0,
                block.timestamp
            )
        );

        bytes32 transientHash = MessageHashUtils.toTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            transientStructHash
        );

        (uint8 transientV, bytes32 transientR, bytes32 transientS) = vm.sign(OWNER_PK, transientHash);

        bytes32 normalStructHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                OWNER,
                SPENDER,
                TEST_APPROVAL_AMOUNT,
                1,
                block.timestamp
            )
        );

        bytes32 normalHash = MessageHashUtils.toTypedDataHash(
            token.DOMAIN_SEPARATOR(),
            normalStructHash
        );

        (uint8 normalV, bytes32 normalR, bytes32 normalS) = vm.sign(OWNER_PK, normalHash);

        uint256 noncesBefore = token.nonces(OWNER);
        assertEq(noncesBefore, 0);
        vm.prank(SPENDER);
        token.transientPermit(
            OWNER,
            SPENDER,
            TEST_APPROVAL_AMOUNT,
            block.timestamp,
            transientV,
            transientR,
            transientS
        );
        uint256 noncesAfter = token.nonces(OWNER);
        assertEq(noncesAfter, 1);

        uint256 noncesBeforeNormal = token.nonces(OWNER);
        assertEq(noncesBeforeNormal, 1);
        vm.prank(SPENDER);
        token.permit(
            OWNER,
            SPENDER,
            TEST_APPROVAL_AMOUNT,
            block.timestamp,
            normalV,
            normalR,
            normalS
        );
        uint256 noncesAfterNormal = token.nonces(OWNER);
        assertEq(noncesAfterNormal, 2);

        uint256 approval = token.transientAllowance(OWNER, SPENDER);

        assertEq(approval, TEST_APPROVAL_AMOUNT);
    }

    function test_cantTransferERC20TokensTransientlyWithPermit() external {
        assertEq(token.balanceOf(SPENDER), 0);

        vm.prank(SPENDER);
        vm.expectRevert();
        token.transientTransferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        vm.prank(SPENDER);
        token.transferFrom(OWNER, SPENDER, TEST_APPROVAL_AMOUNT);

        assertEq(token.balanceOf(SPENDER), TEST_APPROVAL_AMOUNT);
        assertEq(token.balanceOf(OWNER), INITIAL_MINT - TEST_APPROVAL_AMOUNT);
    }
}
