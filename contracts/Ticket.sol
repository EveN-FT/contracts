// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Event.sol";

/**
 * @dev ERC721 token with storage based address management.
 */
abstract contract ERC721Ticket is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    // Optional mapping for an address
    mapping(uint256 => address) private _addresses;

    function _address(uint256 tokenId) internal view returns (address) {
        require(
            _exists(tokenId),
            "ERC721AddressStorage: address query for nonexistent token"
        );

        return _addresses[tokenId];
    }

    /**
     * @dev Sets `_address` as the address of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setAddress(uint256 tokenId, address _addr) internal virtual {
        require(
            _exists(tokenId),
            "ERC721AddressStorage: address set of nonexistent token"
        );
        _addresses[tokenId] = _addr;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        if (_addresses[tokenId] != address(0)) {
            delete _addresses[tokenId];
        }
    }
}

contract Ticket is ERC721Ticket {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Ticket", "tix") {}

    function mintGA(
        address eventAddr,
        string memory tokenURI,
        uint256 amount
    ) public returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](amount);

        require(msg.sender == Event(eventAddr).owner(), "NOT_EVENT_OWNER");

        for (uint256 i = 0; i < amount; ) {
            _tokenIds.increment();

            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURI);
            _setAddress(newItemId, eventAddr);
            ids[i] = newItemId;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }
        return ids;
    }

    function eventAddress(uint256 tokenId) public view returns (address) {
        return _address(tokenId);
    }
}
