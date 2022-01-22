// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {WrappedLockedJewelToken} from "./WrappedLockedJewelToken.sol";
import {IJewelToken} from "./interfaces/IJewelToken.sol";

/// @title JewelEscrow
/// @author 0xTomoyo
/// @notice Escrow contract for minting locked Jewel tokens
contract JewelEscrow {
    /// @notice wlJEWEL contract address
    WrappedLockedJewelToken public immutable lockedJewel;
    /// @notice JEWEL token address
    IJewelToken public immutable jewel;

    constructor(address _jewel) {
        lockedJewel = WrappedLockedJewelToken(msg.sender);
        jewel = IJewelToken(_jewel);
    }

    /// @notice Transfers locked JEWEL from this escrow to the wlJEWEl contract for minting wlJEWEL
    /// @dev Can only be called by the wlJEWEL contract. Any unlocked JEWEL in this escrow is transferred
    /// back to the account that deployed this escrow.
    /// @param account The account that deployed this escrow
    /// @return lock Amount of locked JEWEl transferred to the wlJEWEL contract
    function pull(address account) external returns (uint256 lock) {
        require(msg.sender == address(lockedJewel), "UNAUTHORIZED");
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

    /// @notice Cancels the minting of wLJEWEL by transferring the locked and unlocked JEWEL in this escrow to its deployer
    /// @dev Can only be called by the deployer of this escrow
    function cancel() external {
        require(lockedJewel.escrows(msg.sender) == address(this), "UNAUTHORIZED");
        jewel.transferAll(msg.sender);
    }
}
