// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

contract Ship {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
