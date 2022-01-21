// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {IJewelToken} from "./interfaces/IJewelToken.sol";

contract JewelEscrow {
    address public immutable lockedJewel;
    IJewelToken public immutable jewel;

    constructor(IJewelToken _jewel) {
        lockedJewel = msg.sender;
        jewel = _jewel;
    }

    function pull(address account) external returns (uint256 lock) {
        require(msg.sender == lockedJewel, "UNAUTHORIZED");
        jewel.transfer(account, jewel.balanceOf(address(this)));
        lock = jewel.lockOf(address(this));
        jewel.transferAll(msg.sender);
    }
}