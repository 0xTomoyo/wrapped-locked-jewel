// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IJewelToken} from "./interfaces/IJewelToken.sol";

contract wlJEWEL is ERC20 {
    IJewelToken public immutable jewel;

    constructor(address _jewel) ERC20("Wrapped Locked Jewels", "wlJEWEL", 18) {
        jewel = IJewelToken(_jewel);
    }
}
