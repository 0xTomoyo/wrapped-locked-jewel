// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {IJewelToken} from "../../interfaces/IJewelToken.sol";
import {Vm} from "./Vm.sol";
import {JEWEL} from "./Constants.sol";

contract Utilities is DSTest {
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    IJewelToken internal constant jewel = IJewelToken(JEWEL);

    function mintJewel(address to, uint256 amount) internal {
        vm.store(address(jewel), keccak256(abi.encode(to, 15)), bytes32(amount));
    }
}
