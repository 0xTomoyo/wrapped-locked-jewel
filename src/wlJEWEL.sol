// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IJewelToken} from "./interfaces/IJewelToken.sol";
import {IBank} from "./interfaces/IBank.sol";

contract wlJEWEL is ERC20 {
    IJewelToken public immutable jewel;
    IBank public immutable bank;

    mapping(address => JewelBroker) public brokers;

    constructor(address _jewel, address _bank) ERC20("Wrapped Locked Jewels", "wlJEWEL", 18) {
        jewel = IJewelToken(_jewel);
        bank = IBank(_bank);
    }

    function start(address account) external returns (JewelBroker broker) {
        require(address(brokers[account]) == address(0), "STARTED");
        broker = new JewelBroker(jewel);
        brokers[msg.sender] = broker;
    }

    function mint(address account) external returns (uint256 shares) {
        require(block.number < jewel.lockToBlock(), "UNLOCKED");
        shares = brokers[account].pull(account);
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

contract JewelBroker {
    wlJEWEL public immutable wlJewel;
    IJewelToken public immutable jewel;

    constructor(IJewelToken _jewel) {
        wlJewel = wlJEWEL(msg.sender);
        jewel = _jewel;
    }

    function pull(address account) external returns (uint256 lock) {
        require(msg.sender == address(wlJewel), "UNAUTHORIZED");
        jewel.transfer(account, jewel.balanceOf(address(this)));
        lock = jewel.lockOf(address(this));
        jewel.transferAll(msg.sender);
    }
}
