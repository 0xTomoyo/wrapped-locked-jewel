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
    /// @notice JEWEL token address
    IJewelToken public immutable jewel;
    /// @notice xJEWEL staking address
    IBank public immutable bank;
    /// @notice Returns the escrow address for an account
    mapping(address => address) public escrows;

    /// @dev Implementation address for JewelEscrow
    address internal immutable escrowImplementation;

    constructor(address _jewel, address _bank) ERC20("Wrapped Locked Jewels", "wlJEWEL", 18) {
        jewel = IJewelToken(_jewel);
        bank = IBank(_bank);
        escrowImplementation = address(new JewelEscrow(_jewel));
    }

    /// @notice Deploys an escrow contract for the sender
    /// @dev Must be called before calling mint(). After calling start(),
    /// the locked JEWEL can be transferred to the escrow by calling transferAll(escrow) on the JEWEL contract.
    /// This function will revert if an escrow contract is already deployed.
    /// @return escrow Address of the deployed escrow contract
    function start() external returns (address escrow) {
        require(escrows[msg.sender] == address(0), "STARTED");
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

    /// @notice Mints 1 wlJEWEL for every 1 locked JEWEL in the senders escrow
    /// @dev Must be called after calling start() and transferring the locked JEWEl to the escrow contract
    /// @return shares Amount of wlJEWEL minted
    function mint() external returns (uint256 shares) {
        shares = JewelEscrow(escrows[msg.sender]).pull(msg.sender);
        _mint(msg.sender, shares);
    }

    /// @notice Redeems JEWEL by burning wlJEWEL
    /// @dev The redemption rate can be given by the pricePerShare() function,
    /// e.g. if the pricePerShare() == 0.2, you will receive 0.2 JEWEl for burning 1 wlJEWEL.
    /// The redemption rate increases as the locked JEWEL tokens unlock and as the unlocked
    /// tokens earn yield from xJEWEL staking. This will revert if the pricePerShare() == 0.
    /// Once the locked JEWEL fully unlocks, the pricePerShare() will be >= 1.
    /// @param shares Amount of the senders wlJEWEL to burn
    /// @return amount Amount of JEWEL redeemed and transferred to the sender
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

    /// @notice Unlocks the locked JEWEL that can be unlocked and stakes them to receive xJEWEL
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

    /// @notice The amount of JEWEL that 1 wlJEWEL can be redeemed for
    function pricePerShare() external view returns (uint256) {
        uint256 totalShares = totalSupply;
        return totalShares > 0 ? (((10**decimals) * unlockedJewel()) / totalShares) : 0;
    }

    /// @notice The amount of JEWEL held by this contract that is currently unlocked or can be unlocked
    function unlockedJewel() public view returns (uint256) {
        uint256 bankShares = bank.totalSupply();
        return
            jewel.balanceOf(address(this)) +
            jewel.canUnlockAmount(address(this)) +
            (bankShares > 0 ? ((bank.balanceOf(address(this)) * jewel.balanceOf(address(bank))) / bankShares) : 0);
    }
}
