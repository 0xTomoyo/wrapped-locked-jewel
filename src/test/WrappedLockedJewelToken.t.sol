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

    function setUp() public {
        mintLockedJewel(address(this), 100e18);
        lockedJewel = new WrappedLockedJewelToken(address(jewel), address(bank));
    }

    function testStart() public {
        assertEq(address(lockedJewel.escrows(address(this))), address(0));
        address escrow = lockedJewel.start(address(this));
        assertEq(address(lockedJewel.escrows(address(this))), escrow);
    }

    function testFailStart() public {
        lockedJewel.start(address(this));
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

    function testFailMint() public {
        lockedJewel.mint(address(this));
    }

    function testBurn() public {
        address escrow = lockedJewel.start(address(this));
        jewel.transferAll(escrow);
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = jewel.lockFromBlock();
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
    }

    function testFailBurn() public {
        address escrow = lockedJewel.start(address(this));
        jewel.transferAll(escrow);
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = jewel.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
    }
}
