// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {IJewelToken} from "../../interfaces/IJewelToken.sol";
import {IBank} from "../../interfaces/IBank.sol";
import {Hevm} from "./Hevm.sol";

contract Utilities is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
    IJewelToken internal constant jewel = IJewelToken(0x72Cb10C6bfA5624dD07Ef608027E366bd690048F);
    IBank internal constant bank = IBank(0xA9cE83507D872C5e1273E745aBcfDa849DAA654F);

    function setJewel(address to, uint256 amount) internal {
        hevm.store(address(jewel), keccak256(abi.encode(to, 0)), bytes32(amount));
    }

    function setLockedJewel(address to, uint256 amount) internal {
        hevm.store(address(jewel), keccak256(abi.encode(to, 15)), bytes32(amount));
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
