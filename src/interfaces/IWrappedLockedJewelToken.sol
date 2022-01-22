// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import {IJewelToken} from "./IJewelToken.sol";
import {IBank} from "./IBank.sol";

interface IWrappedLockedJewelToken {
    function jewel() external view returns (IJewelToken);

    function bank() external view returns (IBank);

    function escrows(address) external view returns (address);

    function start(address account) external returns (address escrow);

    function mint(address account) external returns (uint256 shares);

    function burn(uint256 shares) external returns (uint256 amount);

    function unlock() external;

    function pricePerShare() external view returns (uint256);

    function unlockedJewel() external view returns (uint256);
}
