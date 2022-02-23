// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {JewelEscrow} from "../JewelEscrow.sol";
import {Utilities} from "./utils/Utilities.sol";
import {MockWrappedLockedJewelToken} from "./utils/mocks/MockWrappedLockedJewelToken.sol";

contract JewelEscrowTest is Utilities {
    MockWrappedLockedJewelToken internal lockedJewel;
    uint256 internal constant mintAmount = 100e18;

    function setUp() public override {
        super.setUp();
        setLockedJewel(address(this), mintAmount);
        lockedJewel = new MockWrappedLockedJewelToken(address(jewel));
    }

    function testPull() public {
        JewelEscrow escrow = lockedJewel.start();
        jewel.transferAll(address(escrow));

        assertEq(jewel.totalBalanceOf(address(escrow)), mintAmount);
        assertEq(jewel.lockOf(address(escrow)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), 0);
        assertEq(jewel.lockOf(address(lockedJewel)), 0);
        lockedJewel.pull(escrow);
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), mintAmount);
        assertEq(jewel.lockOf(address(lockedJewel)), mintAmount);
    }

    function testPullZero() public {
        JewelEscrow escrow = lockedJewel.start();

        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), 0);
        assertEq(jewel.lockOf(address(lockedJewel)), 0);
        lockedJewel.pull(escrow);
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), 0);
        assertEq(jewel.lockOf(address(lockedJewel)), 0);
    }

    function testPullUnauthorized() public {
        JewelEscrow escrow = lockedJewel.start();
        jewel.transferAll(address(escrow));

        hevm.expectRevert("UNAUTHORIZED");
        escrow.pull(address(this));
    }

    function testPullUnlockedJewel() public {
        uint256 unlockedJewel = mintAmount / 2;
        setJewel(address(this), unlockedJewel);
        JewelEscrow escrow = lockedJewel.start();
        jewel.transferAll(address(escrow));

        assertEq(jewel.totalBalanceOf(address(escrow)), mintAmount + unlockedJewel);
        assertEq(jewel.balanceOf(address(escrow)), unlockedJewel);
        assertEq(jewel.lockOf(address(escrow)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), 0);
        assertEq(jewel.balanceOf(address(lockedJewel)), 0);
        assertEq(jewel.lockOf(address(lockedJewel)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);
        lockedJewel.pull(escrow, address(this));
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.balanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), mintAmount);
        assertEq(jewel.balanceOf(address(lockedJewel)), 0);
        assertEq(jewel.lockOf(address(lockedJewel)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(this)), unlockedJewel);
        assertEq(jewel.balanceOf(address(this)), unlockedJewel);
        assertEq(jewel.lockOf(address(this)), 0);
    }

    function testCancel() public {
        JewelEscrow escrow = lockedJewel.start();
        jewel.transferAll(address(escrow));

        lockedJewel.setEscrow(address(this), address(escrow));
        assertEq(jewel.totalBalanceOf(address(escrow)), mintAmount);
        assertEq(jewel.lockOf(address(escrow)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);
        escrow.cancel();
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);
        assertEq(jewel.lockOf(address(this)), mintAmount);
    }

    function testCancelZero() public {
        JewelEscrow escrow = lockedJewel.start();

        lockedJewel.setEscrow(address(this), address(escrow));
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);
        assertEq(jewel.lockOf(address(this)), mintAmount);
        escrow.cancel();
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);
        assertEq(jewel.lockOf(address(this)), mintAmount);
    }

    function testCancelUnauthorized() public {
        JewelEscrow escrow = lockedJewel.start();
        jewel.transferAll(address(escrow));

        hevm.expectRevert("UNAUTHORIZED");
        escrow.cancel();
    }

    function testCancelUnlockedJewel() public {
        uint256 unlockedJewel = mintAmount / 2;
        setJewel(address(this), unlockedJewel);
        JewelEscrow escrow = lockedJewel.start();
        jewel.transferAll(address(escrow));

        lockedJewel.setEscrow(address(this), address(escrow));
        assertEq(jewel.totalBalanceOf(address(escrow)), mintAmount + unlockedJewel);
        assertEq(jewel.balanceOf(address(escrow)), unlockedJewel);
        assertEq(jewel.lockOf(address(escrow)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);
        escrow.cancel();
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.balanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount + unlockedJewel);
        assertEq(jewel.balanceOf(address(this)), unlockedJewel);
        assertEq(jewel.lockOf(address(this)), mintAmount);
    }
}
