// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Slim1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";

contract Ticket is ERC1155 {
    modifier onlyOwner {
        require(msg.sender == self.owner);
        _;
    }
    // Mint Funglible tokens
    function mint(
        address to,
        uint256 amount,
        address eventAddress,
        string
    ) external onlyOwner {
        _mint(to, amount, eventAddress, metadata);
    }

    // Mint Non-Funglible tokens
    function batchMint(
        address to,
        uint256[] memory amounts,
        address[] memory eventAddresses,
        string[] memory metadata
    ) external onlyOwner {
        _batchMint(to, amounts, eventAddresses, metadata);
    }

    function eventUri(uint256 ticketID) public view returns (string memory) {
        return events[ticketID].metadata;
    }

    function uri(uint256 ticketID) public view returns (string memory) {
        return info[ticketID];
    }

}