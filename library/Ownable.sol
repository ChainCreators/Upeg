// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableBase} from "./OwnableBase.sol";

contract Ownable is OwnableBase {
    constructor() OwnableBase(msg.sender) {}
}
