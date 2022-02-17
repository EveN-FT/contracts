// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Event {
    string public name;
    address public owner;
    string public metadata;

    constructor(
        address _owner,
        string memory _name,
        string memory _metadata
    ) {
        name = _name;
        owner = _owner;
        metadata = _metadata;
    }
}
