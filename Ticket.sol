// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Slim1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";

contract Ticket is ERC115 {
    string public constant name;
    address public constant owner;
    address public constant eventAddress;

    constructor(
        address owner,
        string memory name,
        address eventAddress
    )
    {
        self.name = name;
        self.owner = owner;
        self.eventAddress = eventAddress;
    }

    modifier onlyOwner {
        require(msg.sender == self.owner);
        _;
    }
    // Mint Funglible tokens
    function mint(
        address to,
        uint256 eventAddress,
        uint256 amount
    ) external onlyOwner {
        _mint(to, eventAddress, amount);
    }

    // Mint Non-Funglible tokens
    function batchMint(
        address to,
        address[] memory eventAddresses,
        uint256[] memory amounts
    ) external onlyOwner {
        _batchMint(to, eventAddresses, amounts);
    }
}