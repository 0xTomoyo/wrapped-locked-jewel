// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {WrappedLockedJewelToken} from "../WrappedLockedJewelToken.sol";
import {JewelEscrow} from "../JewelEscrow.sol";
import {IJewelToken} from "../interfaces/IJewelToken.sol";
import {IBank} from "../interfaces/IBank.sol";
import {Hevm} from "./utils/Hevm.sol";
import {JEWEL, BANK} from "./utils/Constants.sol";

contract WrappedLockedJewelTokenTest is DSTest {
    Hevm internal constant vm = Hevm(HEVM_ADDRESS);
    IJewelToken internal constant jewel = IJewelToken(JEWEL);
    IBank internal constant bank = IBank(BANK);

    WrappedLockedJewelToken internal lockedJewel;

    function setUp() public {
        vm.store(address(jewel), keccak256(abi.encode(address(this), 15)), bytes32(uint256(100e18)));

        lockedJewel = new WrappedLockedJewelToken(address(jewel), address(bank));
    }

    function testStart() public {
        assertEq(address(lockedJewel.escrows(address(this))), address(0));
        JewelEscrow escrow = lockedJewel.start(address(this));
        assertEq(address(lockedJewel.escrows(address(this))), address(escrow));
    }

    function testFailStart() public {
        lockedJewel.start(address(this));
        lockedJewel.start(address(this));
    }

    function testMint() public {
        JewelEscrow escrow = lockedJewel.start(address(this));

        uint256 totalBalance = jewel.totalBalanceOf(address(this));
        uint256 locked = jewel.lockOf(address(this));
        assertEq(totalBalance, locked);
        jewel.transferAll(address(escrow));
        assertEq(jewel.totalBalanceOf(address(escrow)), totalBalance);
        assertEq(jewel.lockOf(address(escrow)), locked);
        assertEq(jewel.totalBalanceOf(address(this)), 0);
        assertEq(jewel.lockOf(address(this)), 0);

        assertEq(lockedJewel.balanceOf(address(this)), 0);
        lockedJewel.mint(address(this));
        assertEq(lockedJewel.balanceOf(address(this)), totalBalance);
        assertEq(jewel.totalBalanceOf(address(lockedJewel)), totalBalance);
        assertEq(jewel.lockOf(address(lockedJewel)), locked);
        assertEq(jewel.totalBalanceOf(address(escrow)), 0);
        assertEq(jewel.lockOf(address(escrow)), 0);
    }

    function testFailMint() public {
        lockedJewel.mint(address(this));
    }

    function testBurn() public {
        JewelEscrow escrow = lockedJewel.start(address(this));
        jewel.transferAll(address(escrow));
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = jewel.lockFromBlock();
        uint256 lockToBlock = jewel.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
    }

    function testFailBurn() public {
        JewelEscrow escrow = lockedJewel.start(address(this));
        jewel.transferAll(address(escrow));
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = jewel.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
    }
}
