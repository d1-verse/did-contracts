
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./APP.sol";

abstract contract KeyDefinition is APP { // KVS: Key Value Storage

    // name: "alice"
    // name_hash: keccak256(abi.encodePacked("alice"));
    // full_name: "verse", "alice.verse", "foobar.alice.verse"
    // node: keccak256(abi.encodePacked(parent, name_hash));
    // parent: parent node;

    uint256 constant internal KEY_META = 20;
    uint256 constant internal KEY_NAME = 21;
    uint256 constant internal KEY_TTL = 22;
    uint256 constant internal KEY_MANAGER = 23;
    uint256 constant internal KEY_REGISTRAR = 24;
    uint256 constant internal KEY_RESOLVER = 25;

    uint256 constant internal KEY_NFT_METADATA = 26; // Metadata
    uint256 constant internal KEY_NFT_METADATA_URI = 27; // URI of Metadata
    uint256 constant internal KEY_NFT_IMAGE = 28; // NFT Image, Audio, Video
    uint256 constant internal KEY_NFT_IMAGE_URI = 29; // URI of NFT Image, Audio, Video

    uint256 constant internal KEY_TWITTER = 1000;
    uint256 constant internal KEY_INSTAGRAM = 1001;

    uint256 constant internal KEY_KEY_VOICE_SCORE = 2000; // Key Voice Score

    uint256 constant internal ETHEREUM_LIKE_ADDRESS_BEGIN = 3000;
    uint256 constant internal KEY_ADDRESS_MAIN = KEY_ADDRESS_CUBE;
    uint256 constant internal KEY_ADDRESS_CUBE = (ETHEREUM_LIKE_ADDRESS_BEGIN + 0); // for Cube
    uint256 constant internal KEY_ADDRESS_ETH = (ETHEREUM_LIKE_ADDRESS_BEGIN + 1); // for Ethereum
    uint256 constant internal KEY_ADDRESS_MATIC = (ETHEREUM_LIKE_ADDRESS_BEGIN + 2); // for Polygon
    uint256 constant internal KEY_ADDRESS_HECO = (ETHEREUM_LIKE_ADDRESS_BEGIN + 3); // for Heco
    uint256 internal ETHEREUM_LIKE_ADDRESS_END = (ETHEREUM_LIKE_ADDRESS_BEGIN + 3);

    function setEthLikeAddressEnd(uint256 end) external onlyOperator {
        require(end > ETHEREUM_LIKE_ADDRESS_END, "Append only");
        ETHEREUM_LIKE_ADDRESS_END = end;
    }
}
