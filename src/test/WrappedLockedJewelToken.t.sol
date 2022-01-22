// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {WrappedLockedJewelToken} from "../WrappedLockedJewelToken.sol";
import {JewelEscrow} from "../JewelEscrow.sol";
import {Utilities} from "./utils/Utilities.sol";

contract WrappedLockedJewelTokenTest is Utilities {
    WrappedLockedJewelToken internal lockedJewel;
    uint256 internal constant mintAmount = 100e18;

    function setUp() public {
        mintLockedJewel(address(this), mintAmount);
        lockedJewel = new WrappedLockedJewelToken(address(jewel), address(bank));
    }

    function testStart() public {
        assertEq(address(lockedJewel.escrows(address(this))), address(0));
        address escrow = lockedJewel.start();
        assertEq(address(lockedJewel.escrows(address(this))), escrow);
    }

    function testStartTwice() public {
        lockedJewel.start();
        vm.expectRevert("STARTED");
        lockedJewel.start();
    }

    function testMint() public {
        address escrow = lockedJewel.start();

        uint256 totalBalance = jewel.totalBalanceOf(address(this));
        uint256 locked = jewel.lockOf(address(this));
        assertEq(totalBalance, locked);
        jewel.transferAll(escrow);
        assertEq(jewel.totalBalanceOf(escrow), totalBalance);
        assertEq(jewel.lockOf(escrow), locked);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);

        assertEq(lockedJewel.balanceOf(address(this)), 0);
        lockedJewel.mint();
        assertEq(lockedJewel.balanceOf(address(this)), totalBalance);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), totalBalance);
        assertEq(jewel.lockOf(address(lockedJewel)), locked);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.lockOf(escrow), 0);
    }

    function testMintUnlockedJewel() public {
        uint256 unlockedJewel = mintAmount / 2;
        mintJewel(address(this), unlockedJewel);
        address escrow = lockedJewel.start();

        uint256 totalBalance = jewel.totalBalanceOf(address(this));
        uint256 locked = jewel.lockOf(address(this));
        assertEq(totalBalance, unlockedJewel + locked);
        jewel.transferAll(escrow);
        assertEq(jewel.totalBalanceOf(escrow), totalBalance);
        assertEq(jewel.lockOf(escrow), locked);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);

        assertEq(lockedJewel.balanceOf(address(this)), 0);
        lockedJewel.mint();
        assertEq(lockedJewel.balanceOf(address(this)), locked);
        assertEq(jewel.totalBalanceOf(address(this)), unlockedJewel);
        assertEq(jewel.balanceOf(address(this)), unlockedJewel);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), locked);
        assertEq(jewel.lockOf(address(lockedJewel)), locked);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.lockOf(escrow), 0);
    }

    function testMintCancel() public {
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll(lockToBlock);

        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        assertEq(jewel.lockOf(escrow), mintAmount);
        assertEq(jewel.totalBalanceOf(escrow), mintAmount);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), 0);

        JewelEscrow(escrow).cancel();
        assertEq(jewel.lockOf(escrow), 0);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);

        lockedJewel.mint();
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertEq(jewel.lockOf(escrow), 0);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);
    }

    function testMintBeforeStart() public {
        vm.expectRevert("");
        lockedJewel.mint();
    }

    function testMintAfterUnlock() public {
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll(lockToBlock);

        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        assertEq(jewel.lockOf(escrow), mintAmount);
        assertEq(jewel.totalBalanceOf(escrow), mintAmount);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), 0);

        lockedJewel.mint();
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertEq(jewel.lockOf(escrow), 0);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.balanceOf(address(this)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);
    }

    function testMintAfterTransferAndUnlock() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);

        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll(lockToBlock);
        assertEq(jewel.lockOf(escrow), mintAmount);
        assertEq(jewel.totalBalanceOf(escrow), mintAmount);
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.totalBalanceOf(address(this)), 0);

        lockedJewel.mint();
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertEq(jewel.lockOf(escrow), 0);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.balanceOf(address(this)), mintAmount);
        assertEq(jewel.totalBalanceOf(address(this)), mintAmount);
    }

    function testBurn() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        lockedJewel.mint();

        uint256 lockFromBlock = jewel.lockFromBlock();
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        uint256 unlockedJewel = lockedJewel.unlockedJewel();
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.canUnlockAmount(address(lockedJewel)), mintAmount / 2);
        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertApproxEq(jewel.balanceOf(address(this)), mintAmount / 2, 2);
        assertEq(jewel.balanceOf(address(this)), unlockedJewel);
        assertEq(jewel.canUnlockAmount(address(lockedJewel)), 0);
    }

    function testBurnBeforeUnlock() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        lockedJewel.mint();

        uint256 lockFromBlock = jewel.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        uint256 balance = lockedJewel.balanceOf(address(this));
        vm.expectRevert("EMPTY");
        lockedJewel.burn(balance);
    }

    function testBurnAfterUnlock() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        lockedJewel.mint();

        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll(lockToBlock);

        uint256 unlockedJewel = lockedJewel.unlockedJewel();
        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(jewel.canUnlockAmount(address(lockedJewel)), mintAmount);
        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertApproxEq(jewel.balanceOf(address(this)), mintAmount, 2);
        assertEq(jewel.balanceOf(address(this)), unlockedJewel);
        assertEq(jewel.canUnlockAmount(address(lockedJewel)), 0);
    }

    function testUnlock() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        lockedJewel.mint();

        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll(lockToBlock);

        assertEq(bank.balanceOf(address(lockedJewel)), 0);
        uint256 canUnlockAmount = jewel.canUnlockAmount(address(lockedJewel));
        uint256 bankShares = bank.totalSupply();
        uint256 bankBalance = jewel.balanceOf(address(bank));
        lockedJewel.unlock();
        assertEq(bank.balanceOf(address(lockedJewel)), (canUnlockAmount * bankShares) / bankBalance);
    }

    function testPricePerShare() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        lockedJewel.mint();
        assertEq(lockedJewel.pricePerShare(), 0);

        uint256 lockFromBlock = jewel.lockFromBlock();
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);
        assertApproxEq(lockedJewel.pricePerShare(), 0.5e18, 2);

        vm.roll(lockToBlock);
        assertApproxEq(lockedJewel.pricePerShare(), 1e18, 2);
    }

    function testUnlockedJewel() public {
        address escrow = lockedJewel.start();
        jewel.transferAll(escrow);
        lockedJewel.mint();
        assertEq(lockedJewel.unlockedJewel(), 0);

        uint256 lockFromBlock = jewel.lockFromBlock();
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);
        assertApproxEq(lockedJewel.unlockedJewel(), mintAmount / 2, 2);

        vm.roll(lockToBlock);
        assertApproxEq(lockedJewel.unlockedJewel(), mintAmount, 2);
    }
}
