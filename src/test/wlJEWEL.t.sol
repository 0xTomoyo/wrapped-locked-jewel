// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";

import "./utils/Hevm.sol";
import {wlJEWEL, JewelBroker} from "../wlJEWEL.sol";
import {IJewelToken} from "../interfaces/IJewelToken.sol";
import {IBank} from "../interfaces/IBank.sol";

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
        assertEq(address(wlJewel.brokers(address(this))), address(0));
        JewelBroker broker = wlJewel.start(address(this));
        assertEq(address(wlJewel.brokers(address(this))), address(broker));
    }

    function testFailStart() public {
        wlJewel.start(address(this));
        wlJewel.start(address(this));
    }

    function testMint() public {
        JewelBroker broker = wlJewel.start(address(this));

        uint256 totalBalance = JEWEL.totalBalanceOf(address(this));
        uint256 locked = JEWEL.lockOf(address(this));
        assertEq(totalBalance, locked);
        JEWEL.transferAll(address(broker));
        assertEq(JEWEL.totalBalanceOf(address(broker)), totalBalance);
        assertEq(JEWEL.lockOf(address(broker)), locked);
        assertEq(JEWEL.totalBalanceOf(address(this)), 0);
        assertEq(JEWEL.lockOf(address(this)), 0);

        assertEq(wlJewel.balanceOf(address(this)), 0);
        wlJewel.mint(address(this));
        assertEq(wlJewel.balanceOf(address(this)), totalBalance);
        assertEq(JEWEL.totalBalanceOf(address(wlJewel)), totalBalance);
        assertEq(JEWEL.lockOf(address(wlJewel)), locked);
        assertEq(JEWEL.totalBalanceOf(address(broker)), 0);
        assertEq(JEWEL.lockOf(address(broker)), 0);
    }

    function testBurn() public {
        JewelBroker broker = wlJewel.start(address(this));
        JEWEL.transferAll(address(broker));
        wlJewel.mint(address(this));

        uint256 lockFromBlock = JEWEL.lockFromBlock();
        uint256 lockToBlock = JEWEL.lockToBlock();
        vm.roll((lockFromBlock + lockToBlock) / 2);

        wlJewel.burn(wlJewel.balanceOf(address(this)));
    }

    function testFailBurn() public {
        JewelBroker broker = wlJewel.start(address(this));
        JEWEL.transferAll(address(broker));
        wlJewel.mint(address(this));

        uint256 lockFromBlock = JEWEL.lockFromBlock();
        vm.roll(lockFromBlock - 1);

        wlJewel.burn(wlJewel.balanceOf(address(this)));
    }
}
