// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {JewelEscrow} from "./JewelEscrow.sol";
import {IJewelToken} from "./interfaces/IJewelToken.sol";
import {IBank} from "./interfaces/IBank.sol";

contract WrappedLockedJewelToken is ERC20 {
    IJewelToken public immutable jewel;
    IBank public immutable bank;

    mapping(address => JewelEscrow) public escrows;

    constructor(address _jewel, address _bank) ERC20("Wrapped Locked Jewels", "wlJEWEL", 18) {
        jewel = IJewelToken(_jewel);
        bank = IBank(_bank);
    }

    function start(address account) external returns (JewelEscrow escrow) {
        require(address(escrows[account]) == address(0), "STARTED");
        escrow = new JewelEscrow(jewel);
        escrows[msg.sender] = escrow;
    }

    function mint(address account) external returns (uint256 shares) {
        require(block.number < jewel.lockToBlock(), "UNLOCKED");
        shares = escrows[account].pull(account);
        _mint(account, shares);
    }

    function burn(uint256 shares) external returns (uint256 amount) {
        unlock();
        uint256 bankBalance = bank.balanceOf(address(this));
        require(bankBalance > 0, "EMPTY");
        bank.leave((shares * bankBalance) / totalSupply);
        _burn(msg.sender, shares);
        amount = jewel.balanceOf(address(this));
        jewel.transfer(msg.sender, amount);
    }

    function unlock() public {
        uint256 canUnlockAmount = jewel.canUnlockAmount(address(this));
        if (canUnlockAmount > 0) {
            jewel.unlock();
        }
        uint256 balance = jewel.balanceOf(address(this));
        if (balance > 0) {
            jewel.approve(address(bank), balance);
            bank.enter(balance);
        }
    }

    function unlockedJewel() public view returns (uint256) {
        uint256 bankShares = bank.totalSupply();
        return
            jewel.balanceOf(address(this)) +
            jewel.canUnlockAmount(address(this)) +
            (bankShares > 0 ? ((bank.balanceOf(address(this)) * jewel.balanceOf(address(bank))) / bankShares) : 0);
    }
}
