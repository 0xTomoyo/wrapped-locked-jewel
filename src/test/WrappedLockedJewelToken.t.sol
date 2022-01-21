// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {WrappedLockedJewelToken} from "../WrappedLockedJewelToken.sol";
import {JewelEscrow} from "../JewelEscrow.sol";
import {IJewelToken} from "../interfaces/IJewelToken.sol";
import {IBank} from "../interfaces/IBank.sol";
import {Hevm} from "./utils/Hevm.sol";

contract WrappedLockedJewelTokenTest is DSTest {
    Hevm internal constant vm = Hevm(HEVM_ADDRESS);
    IJewelToken internal constant JEWEL = IJewelToken(0x72Cb10C6bfA5624dD07Ef608027E366bd690048F);
    IBank internal constant bank = IBank(0xA9cE83507D872C5e1273E745aBcfDa849DAA654F);

    WrappedLockedJewelToken internal lockedJewel;

    function setUp() public {
        vm.store(address(JEWEL), keccak256(abi.encode(address(this), 15)), bytes32(uint256(100e18)));

        lockedJewel = new WrappedLockedJewelToken(address(JEWEL), address(bank));
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

        uint256 totalBalance = JEWEL.totalBalanceOf(address(this));
        uint256 locked = JEWEL.lockOf(address(this));
        assertEq(totalBalance, locked);
        JEWEL.transferAll(address(escrow));
        assertEq(JEWEL.totalBalanceOf(address(escrow)), totalBalance);
        assertEq(JEWEL.lockOf(address(escrow)), locked);
        assertEq(JEWEL.totalBalanceOf(address(this)), 0);
        assertEq(JEWEL.lockOf(address(this)), 0);

        assertEq(lockedJewel.balanceOf(address(this)), 0);
        lockedJewel.mint(address(this));
        assertEq(lockedJewel.balanceOf(address(this)), totalBalance);
        assertEq(JEWEL.totalBalanceOf(address(lockedJewel)), totalBalance);
        assertEq(JEWEL.lockOf(address(lockedJewel)), locked);
        assertEq(JEWEL.totalBalanceOf(address(escrow)), 0);
        assertEq(JEWEL.lockOf(address(escrow)), 0);
    }

    function testFailMint() public {
        lockedJewel.mint(address(this));
    }

    function testBurn() public {
        JewelEscrow escrow = lockedJewel.start(address(this));
        JEWEL.transferAll(address(escrow));
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = JEWEL.lockFromBlock();
        uint256 lockToBlock = JEWEL.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
    }

    function testFailBurn() public {
        JewelEscrow escrow = lockedJewel.start(address(this));
        JEWEL.transferAll(address(escrow));
        lockedJewel.mint(address(this));

        uint256 lockFromBlock = JEWEL.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        lockedJewel.burn(lockedJewel.balanceOf(address(this)));
    }
}
