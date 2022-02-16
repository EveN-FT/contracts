// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Event {
    string public constant name;
    address public constant owner;
    string public constant metadata;

    constructor(
        address owner,
        string memory name,
        string memory metadata
    )
    {
        self.name = name;
        self.owner = owner;
        self.metadata = metadata;
    }
}