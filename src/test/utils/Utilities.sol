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
        vm.store(address(jewel), keccak256(abi.encode(to, 0)), bytes32(amount));
    }

    function mintLockedJewel(address to, uint256 amount) internal {
        vm.store(address(jewel), keccak256(abi.encode(to, 15)), bytes32(amount));
    }

    function assertApproxEq(
        uint256 a,
        uint256 b,
        uint256 maxDelta
    ) internal virtual {
        uint256 delta = a > b ? a - b : b - a;

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("  Expected", a);
            emit log_named_uint("    Actual", b);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }
}
