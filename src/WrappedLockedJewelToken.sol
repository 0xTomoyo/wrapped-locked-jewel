// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {JewelEscrow} from "./JewelEscrow.sol";
import {IJewelToken} from "./interfaces/IJewelToken.sol";
import {IBank} from "./interfaces/IBank.sol";

/// @title WrappedLockedJewelToken
/// @author 0xTomoyo
/// @notice A wrapped, tradable version of locked Jewel tokens
contract WrappedLockedJewelToken is ERC20 {
    IJewelToken public immutable jewel;
    IBank public immutable bank;
    mapping(address => address) public escrows;
    address internal immutable escrowImplementation;

    constructor(address _jewel, address _bank) ERC20("Wrapped Locked Jewels", "wlJEWEL", 18) {
        jewel = IJewelToken(_jewel);
        bank = IBank(_bank);
        escrowImplementation = address(new JewelEscrow(_jewel));
    }

    function start(address account) external returns (address escrow) {
        require(escrows[account] == address(0), "STARTED");
        // Creates a minimal proxy clone of the escrow contract
        address implementation = escrowImplementation; // Necessary since assembly can't access immutable variables
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            escrow := create(0, ptr, 0x37)
        }
        escrows[msg.sender] = escrow;
    }

    function mint(address account) external returns (uint256 shares) {
        shares = JewelEscrow(escrows[account]).pull(account);
        _mint(account, shares);
    }

    function burn(uint256 shares) external returns (uint256 amount) {
        unlock();
        uint256 bankBalance = bank.balanceOf(address(this));
        // Prevents a user from redeeming 0 JEWEL from wlJEWEL, i.e. when pricePerShare() == 0
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
        // Converts all unlocked tokens to xJEWEL
        uint256 balance = jewel.balanceOf(address(this));
        if (balance > 0) {
            jewel.approve(address(bank), balance);
            bank.enter(balance);
        }
    }

    function pricePerShare() external view returns (uint256) {
        uint256 totalShares = totalSupply;
        return totalSupply > 0 ? (((10**decimals) * unlockedJewel()) / totalShares) : 0;
    }

    function unlockedJewel() public view returns (uint256) {
        uint256 bankShares = bank.totalSupply();
        return
            jewel.balanceOf(address(this)) +
            jewel.canUnlockAmount(address(this)) +
            (bankShares > 0 ? ((bank.balanceOf(address(this)) * jewel.balanceOf(address(bank))) / bankShares) : 0);
    }
}
