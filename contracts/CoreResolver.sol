// SPDX-License-Identifier: MIT

import "./Common/KVStorage.sol";
import "./Common/APP.sol";

pragma solidity ^0.8.9;

contract CoreResolver is KVStorage {

    constructor(address core_db) {
        initApp(core_db, true);
    }

    // full_name[www.alice.verse] => name_array[www, alice, verse]
    function encodeNameArrayToNode(string[] memory name_array) external view returns (bytes32) {
        bytes32 node = _coreDB.rootNode();
        for (uint256 i = name_array.length; i > 0; i--) {
            node = encodeNameToNode(node, name_array[i-1]);
        }
        return node;
    }

    function abiBytesToAddressWithTimestamp(bytes memory bys) public pure returns(address payable addr, uint64 time_stamp) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
        time_stamp = uint64(num & type(uint96).max);
        return (addr, time_stamp);
    }

    function getNodeNameFull(bytes32 node) public view returns (string memory) {
        string memory full_name = abiBytesToString(_coreDB.getNodeItem(node, bytes32(KEY_NAME)));
        bytes32 parent = _coreDB.getNodeParent(node);
        bytes32 root_node = _coreDB.rootNode();
        while (parent != root_node) {
            string memory parent_name = abiBytesToString(_coreDB.getNodeItem(parent, bytes32(KEY_NAME)));
            full_name = string(abi.encodePacked(full_name, ".", parent_name));
            parent = _coreDB.getNodeParent(parent);
        }
        return full_name;
    }

    function getNodeName(bytes32 node) public view returns (string memory) {
        return abiBytesToString(_coreDB.getNodeItem(node, bytes32(KEY_NAME)));
    }

    function getTTL(bytes32 node) external view returns (uint64) {
        return abiBytesToUint64(_coreDB.getNodeItem(node, bytes32(KEY_TTL)));
    }

    function getTwitter(bytes32 node) external view returns (string memory) {
        // address main_address = getMainAddress(node);
        address owner = _coreDB.getNodeOwner(node);
        return abiBytesToString(_coreDB.getOwnerItem(owner, encodeItemKey(node, KEY_TWITTER)));
    }

    function getInstagram(bytes32 node) external view returns (string memory) {
        // address main_address = getMainAddress(node);
        address owner = _coreDB.getNodeOwner(node);
        return abiBytesToString(_coreDB.getOwnerItem(owner, encodeItemKey(node, KEY_INSTAGRAM)));
    }

    function getKeyVoiceScore(address main_address_or_owner) external view returns (uint256) {
        return abiBytesToUint256(_coreDB.getOwnerItem(main_address_or_owner, encodeItemKey(bytes32(0), KEY_KEY_VOICE_SCORE)));
    }

    function getNftMetadataURI(bytes32 node) external view returns (string memory) {
        return abiBytesToString(_coreDB.getNodeItem(node, bytes32(KEY_NFT_METADATA_URI)));
    }

    function getReverse(address main_address) public view returns (bytes32, string memory) {
        bytes32 node = _coreDB.reverseRecord(main_address);
        string memory name = getNodeNameFull(node);
        return (node, name);
    }

    function getResolver(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(_coreDB.getNodeItem(node, bytes32(KEY_RESOLVER)));
    }

    function getResolverWithTimestamp(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithTimestamp(_coreDB.getNodeItem(node, bytes32(KEY_RESOLVER)));
    }

    function getRegistrarWithTimestamp(bytes32 node) public view returns (address, uint64) {
        return abiBytesToAddressWithTimestamp(_coreDB.getNodeItem(node, bytes32(KEY_REGISTRAR)));
    }

    function getManagerWithTimestamp(bytes32 node) public view returns (address, uint64) {
        return abiBytesToAddressWithTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, KEY_MANAGER)));
    }

    function getMainAddressWithTimestamp(bytes32 node) public view returns (address, uint64) {
        return abiBytesToAddressWithTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, KEY_ADDRESS_MAIN)));
    }

    function getTeamMembers(bytes32 node) external view returns (address, address, address, address) {
        return (getNodeOwner(node), getManager(node), getMainAddress(node), getRegistrar(node));
    }

    function getEthLikeAddress(bytes32 node, uint256 item_key) external view returns (address) {
        require(item_key >= ETHEREUM_LIKE_ADDRESS_BEGIN && item_key <= ETHEREUM_LIKE_ADDRESS_END, "Item key is not an ethereum-like address");
        return abiBytesToAddressWithoutTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
    }

    function getEthLikeAddressList(bytes32 node) external view returns (address[] memory) {
        uint256 length = ETHEREUM_LIKE_ADDRESS_END + 1 - ETHEREUM_LIKE_ADDRESS_BEGIN;
        address[] memory addr_array = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 item_key = ETHEREUM_LIKE_ADDRESS_BEGIN + i;
            addr_array[i] = abiBytesToAddressWithoutTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
        }
        return addr_array;
    }

    function getEthLikeAddressWithTimestamp(bytes32 node, uint256 item_key) external view returns (address, uint64) {
        require(item_key >= ETHEREUM_LIKE_ADDRESS_BEGIN && item_key <= ETHEREUM_LIKE_ADDRESS_END, "Item key is not an ethereum-like address");
        return abiBytesToAddressWithTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
    }

    function getEthLikeAddressListWithTimestamp(bytes32 node) external view returns (address[] memory, uint64[] memory) {
        uint256 length = ETHEREUM_LIKE_ADDRESS_END + 1 - ETHEREUM_LIKE_ADDRESS_BEGIN;
        address[] memory addr_array = new address[](length);
        uint64[] memory time_array = new uint64[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 item_key = ETHEREUM_LIKE_ADDRESS_BEGIN + i;
            (addr_array[i], time_array[i]) = abiBytesToAddressWithTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
        }
        return (addr_array, time_array);
    }

}


