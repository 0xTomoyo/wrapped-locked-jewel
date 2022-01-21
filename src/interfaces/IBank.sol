// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;

interface IBank {
    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}
