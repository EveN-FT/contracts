// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol";

contract Ticket is ERC115 {
    string public constant name;
    string public constant symbol;
    address public constant owner;
    address public constant eventAddress;

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        address eventAddress
    )
    {
        self.name = name;
        self.symbol = symbol;
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
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }
    // Mint Non-Funglible tokens
    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _batchMint(to, ids, amounts, "");
    }
}