// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {IJewelToken} from "./interfaces/IJewelToken.sol";

/// @title JewelEscrow
/// @author 0xTomoyo
/// @notice Escrow contract for minting locked Jewel tokens
contract JewelEscrow {
    address public immutable lockedJewel;
    IJewelToken public immutable jewel;

    constructor(address _jewel) {
        lockedJewel = msg.sender;
        jewel = IJewelToken(_jewel);
    }

    function pull(address account) external returns (uint256 lock) {
        require(msg.sender == lockedJewel, "UNAUTHORIZED");
        // Returns unlocked JEWEL back to the user
        // This stops any new mints after jewel tokens have fully unlocked
        // This is necessary to prevent diluting the xJEWEL rewards of wlJEWEL holders
        uint256 canUnlockAmount = jewel.canUnlockAmount(address(this));
        if (canUnlockAmount > 0) {
            jewel.unlock();
        }
        uint256 balance = jewel.balanceOf(address(this));
        if (balance > 0) {
            jewel.transfer(account, balance);
        }
        lock = jewel.lockOf(address(this));
        jewel.transferAll(msg.sender);
    }
}
