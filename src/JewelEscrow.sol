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
        jewel.transfer(account, jewel.balanceOf(address(this)));
        lock = jewel.lockOf(address(this));
        jewel.transferAll(msg.sender);
    }
}
