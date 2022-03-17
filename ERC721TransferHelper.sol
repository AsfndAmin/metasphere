// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC-721 Transfer Helper
/// @notice This contract provides modules the ability to transfer user ERC-721s
contract ERC721TransferHelper {
    constructor() {}

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
    }
}
