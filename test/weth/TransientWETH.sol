// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TestTransientWETH} from "./TestTransientWETH.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TransientWETH is Test {
    TestTransientWETH token;
    address immutable OWNER;
    address immutable SPENDER;

    constructor() {
        OWNER = makeAddr("owner");
        SPENDER = makeAddr("spender");
    }

    function setUp() external {
        vm.prank(OWNER);
        token = new TestTransientWETH();
        vm.stopPrank();
    }

    function test_depositAndWithdraw() external {
        vm.deal(OWNER, 1 ether);
        vm.prank(OWNER);
        token.deposit{value: 1 ether}();


        assertEq(token.balanceOf(OWNER), 1 ether);
        assertEq(address(OWNER).balance, 0);

        vm.prank(OWNER);
        token.withdraw(1 ether);

        assertEq(token.balanceOf(OWNER), 0);
        assertEq(address(OWNER).balance, 1 ether);
    }

    function test_sendETHAndWithdraw() external {
        vm.deal(OWNER, 1 ether);
        vm.prank(OWNER);
        (bool success, ) = address(token).call{value: 1 ether}("");
        assertTrue(success);

        assertEq(token.balanceOf(OWNER), 1 ether);
        assertEq(address(OWNER).balance, 0);

        vm.prank(OWNER);
        token.withdraw(1 ether);

        assertEq(token.balanceOf(OWNER), 0);
        assertEq(address(OWNER).balance, 1 ether);
    }

}
