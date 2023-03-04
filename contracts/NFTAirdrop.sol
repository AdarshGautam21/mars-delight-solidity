//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTAirdrop is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ERC721("NFT Aidrop Demo", "NAD") {
        console.log("Contract has been deployed!");
    }

    // Airdrop NFTs
    function airdropNfts(address[] calldata wAddresses) public onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
            _mintSingleNFT(wAddresses[i]);
        }
    }

    function _mintSingleNFT(address wAddress) private {
        uint newTokenID = _tokenIds.current();
        _safeMint(wAddress, newTokenID);
        _tokenIds.increment();
    }
}
