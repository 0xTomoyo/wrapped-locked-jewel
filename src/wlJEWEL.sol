// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IJewelToken} from "./interfaces/IJewelToken.sol";

contract wlJEWEL is ERC20 {
    IJewelToken public immutable jewel;

    mapping(address => JewelBroker) public brokers;

    constructor(address _jewel) ERC20("Wrapped Locked Jewels", "wlJEWEL", 18) {
        jewel = IJewelToken(_jewel);
    }

    function start(address account) external returns (JewelBroker broker) {
        require(address(brokers[account]) == address(0), "cannot restart");
        broker = new JewelBroker();
        brokers[msg.sender] = broker;
    }

    function mint(address account) external returns (uint256 locked) {
        locked = brokers[account].pull(account);
        _mint(account, locked);
    }

    function burn(uint256 locked) external returns (uint256 amount) {
        jewel.unlock();
        amount = (locked * jewel.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, locked);
        jewel.transfer(msg.sender, amount);
    }
}

contract JewelBroker {
    wlJEWEL public immutable wlJewel;
    IJewelToken public immutable jewel;

    constructor() {
        wlJewel = wlJEWEL(msg.sender);
        jewel = wlJEWEL(msg.sender).jewel();
    }

    function pull(address account) external returns (uint256 lock) {
        require(msg.sender == address(wlJewel), "can only pull from wlJewel");
        jewel.transfer(account, jewel.balanceOf(address(this)));
        lock = jewel.lockOf(address(this));
        jewel.transferAll(msg.sender);
    }
}
