// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "./Event.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;
  /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 amount
  );

  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] amounts
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  event URI(string value, uint256 indexed id);

  /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

  mapping(address => mapping(uint256 => uint256)) public balanceOf;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  // Mapping from ticket ID to event address
  mapping(uint256 => address) public events;

  // Mapping from ticket ID to ticket info
  mapping(uint256 => string) public info;

  /*///////////////////////////////////////////////////////////////
                            ERROR LOGIC
    //////////////////////////////////////////////////////////////*/

  error InsufficientBalance(uint256 requested, uint256 available);

  /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

  function uri(uint256 id) public view virtual returns (string memory);

  /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) public virtual {
    require(
      msg.sender == from || isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );

    if (amount > balanceOf[from][id])
      revert InsufficientBalance({
        requested: amount,
        available: balanceOf[from][id]
      });

    balanceOf[from][id] -= amount;
    balanceOf[to][id] += amount;

    emit TransferSingle(msg.sender, from, to, id, amount);

    require(
      to.code.length == 0
        ? to != address(0)
        : ERC1155TokenReceiver(to).onERC1155Received(
          msg.sender,
          from,
          id,
          amount,
          ""
        ) == ERC1155TokenReceiver.onERC1155Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual {
    uint256 idsLength = ids.length; // Saves MLOADs.

    require(idsLength == amounts.length, "LENGTH_MISMATCH");

    require(
      msg.sender == from || isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );

    for (uint256 i = 0; i < idsLength; ) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      if (amounts[i] > balanceOf[from][id])
        revert InsufficientBalance({
          requested: amounts[i],
          available: balanceOf[from][id]
        });

      balanceOf[from][id] -= amount;
      balanceOf[to][id] += amount;

      // An array can't have a total length
      // larger than the max uint256 value.
      unchecked {
        i++;
      }
    }

    emit TransferBatch(msg.sender, from, to, ids, amounts);

    require(
      to.code.length == 0
        ? to != address(0)
        : ERC1155TokenReceiver(to).onERC1155BatchReceived(
          msg.sender,
          from,
          ids,
          amounts,
          ""
        ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function balanceOfBatch(address[] memory owners, uint256[] memory ids)
    public
    view
    virtual
    returns (uint256[] memory balances)
  {
    uint256 ownersLength = owners.length; // Saves MLOADs.

    require(ownersLength == ids.length, "LENGTH_MISMATCH");

    balances = new uint256[](owners.length);

    // Unchecked because the only math done is incrementing
    // the array index counter which cannot possibly overflow.
    unchecked {
      for (uint256 i = 0; i < ownersLength; i++) {
        balances[i] = balanceOf[owners[i]][ids[i]];
      }
    }
  }

  /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
      interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
  }

  /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(
    address to,
    uint256 amount,
    address eventAddress,
    string memory metadata
  ) internal {
    require(msg.sender == Event(eventAddress).owner(), "NOT_EVENT_OWNER");

    uint256 id = _tokenSupply.current();
    balanceOf[to][id] += amount;
    info[id] = metadata;
    events[id] = eventAddress;

    emit TransferSingle(msg.sender, address(0), to, id, amount);

    require(
      to.code.length == 0
        ? to != address(0)
        : ERC1155TokenReceiver(to).onERC1155Received(
          msg.sender,
          address(0),
          id,
          amount,
          ""
        ) == ERC1155TokenReceiver.onERC1155Received.selector,
      "UNSAFE_RECIPIENT"
    );
    // after minting
    _tokenSupply.increment();
  }

  function _batchMint(
    address to,
    uint256[] memory amounts,
    address[] memory eventAddresses,
    string[] memory metadata
  ) internal {
    uint256 eventsLength = eventAddresses.length; // Saves MLOADs.

    require(eventsLength == amounts.length, "LENGTH_MISMATCH");

    uint256[] memory ids = new uint256[](eventsLength);

    for (uint256 i = 0; i < eventsLength; ) {
      require(
        msg.sender == Event(eventAddresses[i]).owner(),
        "NOT_EVENT_OWNER"
      );

      uint256 id = _tokenSupply.current();
      ids[i] = id;

      balanceOf[to][id] += amounts[i];
      info[id] = metadata[i];
      events[id] = eventAddresses[i];

      // after minting
      _tokenSupply.increment();
      // An array can't have a total length
      // larger than the max uint256 value.
      unchecked {
        i++;
      }
    }

    emit TransferBatch(msg.sender, address(0), to, ids, amounts);

    require(
      to.code.length == 0
        ? to != address(0)
        : ERC1155TokenReceiver(to).onERC1155BatchReceived(
          msg.sender,
          address(0),
          ids,
          amounts,
          ""
        ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function _batchBurn(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal {
    uint256 idsLength = ids.length; // Saves MLOADs.

    require(idsLength == amounts.length, "LENGTH_MISMATCH");

    for (uint256 i = 0; i < idsLength; ) {
      balanceOf[from][ids[i]] -= amounts[i];

      // An array can't have a total length
      // larger than the max uint256 value.
      unchecked {
        i++;
      }
    }

    emit TransferBatch(msg.sender, from, address(0), ids, amounts);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal {
    balanceOf[from][id] -= amount;

    emit TransferSingle(msg.sender, from, address(0), id, amount);
  }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external returns (bytes4);
}

contract Ticket is ERC1155 {
  // Mint Funglible tokens
  function mint(
    address to,
    uint256 amount,
    address eventAddress,
    string memory metadata
  ) public {
    _mint(to, amount, eventAddress, metadata);
  }

  // Mint Non-Funglible tokens
  function batchMint(
    address to,
    uint256[] memory amounts,
    address[] memory eventAddresses,
    string[] memory metadata
  ) public {
    _batchMint(to, amounts, eventAddresses, metadata);
  }

  function eventUri(uint256 ticketID) public view returns (string memory) {
    return Event(events[ticketID]).metadata();
  }

  function uri(uint256 ticketID) public view override returns (string memory) {
    return info[ticketID];
  }
}
