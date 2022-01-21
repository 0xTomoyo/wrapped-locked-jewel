// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";

import "./utils/Hevm.sol";
import {IJewelToken} from "../interfaces/IJewelToken.sol";

contract wlJEWELTest is DSTest {
    Hevm constant vm = Hevm(HEVM_ADDRESS);

    IJewelToken constant JEWEL = IJewelToken(0x72Cb10C6bfA5624dD07Ef608027E366bd690048F);

    function setUp() public {
        vm.store(address(JEWEL), keccak256(abi.encode(address(this), 15)), bytes32(uint256(100_000 * 1e18)));
        emit log_uint(JEWEL.totalSupply());
    }

    function testExample() public {
        assertTrue(true);
    }
}
