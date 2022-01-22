// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {JewelEscrow} from "../../../JewelEscrow.sol";
import {IJewelToken} from "../../../interfaces/IJewelToken.sol";

contract MockWrappedLockedJewelToken {
    address public immutable jewel;
    mapping(address => address) public escrows;

    constructor(address _jewel) {
        jewel = _jewel;
    }

    function start() external returns (JewelEscrow) {
        return new JewelEscrow(jewel);
    }

    function pull(JewelEscrow escrow) external returns (uint256) {
        return escrow.pull(address(this));
    }

    function pull(JewelEscrow escrow, address account) external returns (uint256) {
        return escrow.pull(account);
    }

    function setEscrow(address account, address escrow) external {
        escrows[account] = escrow;
    }
}
