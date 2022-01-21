// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {WrappedLockedJewelToken} from "../WrappedLockedJewelToken.sol";
import {JewelEscrow} from "../JewelEscrow.sol";
import {Utilities} from "./utils/Utilities.sol";
import {IBank} from "../interfaces/IBank.sol";
import {BANK} from "./utils/Constants.sol";

contract WrappedLockedJewelTokenTest is Utilities {
    IBank internal constant bank = IBank(BANK);
    WrappedLockedJewelToken internal lockedJewel;
    uint256 internal constant mintAmount = 100e18;

    function setUp() public {
        mintLockedJewel(address(this), mintAmount);
        lockedJewel = new WrappedLockedJewelToken(address(jewel), address(bank));
    }

    function testStart() public {
        assertEq(address(lockedJewel.escrows(address(this))), address(0));
        address escrow = lockedJewel.start(address(this));
        assertEq(address(lockedJewel.escrows(address(this))), escrow);
    }

    function testStartTwice() public {
        lockedJewel.start(address(this));
        vm.expectRevert("STARTED");
        lockedJewel.start(address(this));
    }

    function testMint() public {
        address escrow = lockedJewel.start(address(this));

        uint256 totalBalance = jewel.totalBalanceOf(address(this));
        uint256 locked = jewel.lockOf(address(this));
        assertEq(totalBalance, locked);
        jewel.transferAll(escrow);
        assertEq(jewel.totalBalanceOf(escrow), totalBalance);
        assertEq(jewel.lockOf(escrow), locked);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);

        assertEq(lockedJewel.balanceOf(address(this)), 0);
        lockedJewel.mint(address(this));
        assertEq(lockedJewel.balanceOf(address(this)), totalBalance);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), totalBalance);
        assertEq(jewel.lockOf(address(lockedJewel)), locked);
        assertEq(jewel.totalBalanceOf(escrow), 0);
        assertEq(jewel.lockOf(escrow), 0);
    }

    function testMintBeforeStart() public {
        vm.expectRevert("");
        lockedJewel.mint(address(this));
    }

    function testBurn() public {
        address escrow = lockedJewel.start(address(this));
        jewel.transferAll(escrow);
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = jewel.lockFromBlock();
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(lockedJewel.unlockedJewel(), mintAmount / 2);
        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertApproxEq(jewel.balanceOf(address(this)), mintAmount / 2, 2);
        assertEq(lockedJewel.unlockedJewel(), 0);
    }

    function testBurnBeforeUnlock() public {
        address escrow = lockedJewel.start(address(this));
        jewel.transferAll(escrow);
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = jewel.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        uint256 balance = lockedJewel.balanceOf(address(this));
        vm.expectRevert("EMPTY");
        lockedJewel.burn(balance);
    }

    function testBurnAfterUnlock() public {
        address escrow = lockedJewel.start(address(this));
        jewel.transferAll(escrow);
        lockedJewel.mint(address(this));

        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll(lockToBlock);

        assertEq(jewel.balanceOf(address(this)), 0);
        assertEq(lockedJewel.unlockedJewel(), mintAmount);
        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
        assertEq(lockedJewel.balanceOf(address(this)), 0);
        assertApproxEq(jewel.balanceOf(address(this)), mintAmount, 2);
        assertEq(lockedJewel.unlockedJewel(), 0);
    }
}
