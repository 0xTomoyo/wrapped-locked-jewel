// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {wlJEWEL} from "../wlJEWEL.sol";
import {JewelEscrow} from "../JewelEscrow.sol";
import {IJewelToken} from "../interfaces/IJewelToken.sol";
import {IBank} from "../interfaces/IBank.sol";
import {Hevm} from "./utils/Hevm.sol";

contract wlJEWELTest is DSTest {
    Hevm internal constant vm = Hevm(HEVM_ADDRESS);
    IJewelToken internal constant JEWEL = IJewelToken(0x72Cb10C6bfA5624dD07Ef608027E366bd690048F);
    IBank internal constant bank = IBank(0xA9cE83507D872C5e1273E745aBcfDa849DAA654F);

    wlJEWEL internal wlJewel;

    function setUp() public {
        vm.store(address(JEWEL), keccak256(abi.encode(address(this), 15)), bytes32(uint256(100e18)));

        wlJewel = new wlJEWEL(address(JEWEL), address(bank));
    }

    function testStart() public {
        assertEq(address(wlJewel.escrows(address(this))), address(0));
        JewelEscrow escrow = wlJewel.start(address(this));
        assertEq(address(wlJewel.escrows(address(this))), address(escrow));
    }

    function testFailStart() public {
        wlJewel.start(address(this));
        wlJewel.start(address(this));
    }

    function testMint() public {
        JewelEscrow escrow = wlJewel.start(address(this));

        uint256 totalBalance = JEWEL.totalBalanceOf(address(this));
        uint256 locked = JEWEL.lockOf(address(this));
        assertEq(totalBalance, locked);
        JEWEL.transferAll(address(escrow));
        assertEq(JEWEL.totalBalanceOf(address(escrow)), totalBalance);
        assertEq(JEWEL.lockOf(address(escrow)), locked);
        assertEq(JEWEL.totalBalanceOf(address(this)), 0);
        assertEq(JEWEL.lockOf(address(this)), 0);

        assertEq(wlJewel.balanceOf(address(this)), 0);
        wlJewel.mint(address(this));
        assertEq(wlJewel.balanceOf(address(this)), totalBalance);
        assertEq(JEWEL.totalBalanceOf(address(wlJewel)), totalBalance);
        assertEq(JEWEL.lockOf(address(wlJewel)), locked);
        assertEq(JEWEL.totalBalanceOf(address(escrow)), 0);
        assertEq(JEWEL.lockOf(address(escrow)), 0);
    }

    function testFailMint() public {
        wlJewel.mint(address(this));
    }

    function testBurn() public {
        JewelEscrow escrow = wlJewel.start(address(this));
        JEWEL.transferAll(address(escrow));
        wlJewel.mint(address(this));

        uint256 lockFromBlock = JEWEL.lockFromBlock();
        uint256 lockToBlock = JEWEL.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        wlJewel.burn(wlJewel.balanceOf(address(this)));
    }

    function testFailBurn() public {
        JewelEscrow escrow = wlJewel.start(address(this));
        JEWEL.transferAll(address(escrow));
        wlJewel.mint(address(this));

        uint256 lockFromBlock = JEWEL.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        wlJewel.burn(wlJewel.balanceOf(address(this)));
    }
}
