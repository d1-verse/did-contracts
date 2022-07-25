
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICoreDB {

    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        mapping(bytes32 => bytes) db;
        // Name, TTL, Registrar, belong to node-DB without Item-Key-Encode
        // Manager, MainAddress, HecoAddress, EthAddress..., belong to owner-DB with Item-Key-Encode
    }

    function coreDAO() external view returns (address);
    function coreRegistrar() external view returns (address);
    function coreNFT() external view returns (address);
    function coreSW() external view returns (address);
    function coreDB() external view returns (address);
    function coreResolver() external view returns (address);
    function coreMeta() external view returns (address, address, address, address, address, address);
    function metadataURI() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function reverseRecord(address main_address) external view returns (bytes32);
    function nodeLock(bytes32 node) external view returns (bool);

    function getOwnerItem(address owner, bytes32 item_key) external view returns (bytes memory);
    function getNodeItem(bytes32 node, bytes32 item_key) external view returns (bytes memory);
    function getNodeOwnerItem(bytes32 node, bytes32 item_key) external view returns (bytes memory);

    function getOwnerItemLength(address owner, bytes32 item_key) external view returns (uint256);
    function getNodeItemLength(bytes32 node, bytes32 item_key) external view returns (uint256);
    function getNodeOwnerItemLength(bytes32 node, bytes32 item_key) external view returns (uint256);

    function getNodeOwner(bytes32 node) external view returns (address);
    function getNodeParent(bytes32 node) external view returns (bytes32);
    function getNodeExpire(bytes32 node) external view returns (uint64);

    function increaseBalance(address owner, uint256 amount) external;
    function decreaseBalance(address owner, uint256 amount) external;
    function increaseTotalSupply(uint256 amount) external;
    function decreaseTotalSupply(uint256 amount) external;

    function setReverse(address main_address, bytes32 node) external;
    function initNode(bytes32 node, bytes32 parent, address owner, uint64 expire, bool locked) external;
    function setNodeOwner(bytes32 node, address owner) external;
    function setNodeExpire(bytes32 node, uint64 expire) external;

    function lockNode(bytes32 node, bool locked) external;
    function lockOwner(address owner, bool locked) external;
    function lockNodeItem(bytes32 node, bytes32 item_key, bool locked) external;
    function lockOwnerItem(address owner, bytes32 item_key, bool locked) external;

    function lockNodeBatch(bytes32[] memory nodes, bool locked) external;
    function lockOwnerBatch(address[] memory owners, bool locked) external;
    function lockNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bool locked) external;
    function lockOwnerItemBatch(address owner, bytes32[] memory item_keys, bool locked) external;

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external;
    function setOwnerItem(address owner, bytes32 item_key, bytes memory item_value) external;
    function setNodeOwnerItem(bytes32 node, bytes32 item_key, bytes memory item_value) external;
    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external;
    function setOwnerItemBatch(address owner, bytes32[] memory item_keys, bytes[] memory item_values) external;

    function deleteNodeItem(bytes32 node, bytes32 item_key) external;
    function deleteOwnerItem(address owner, bytes32 item_key) external;
    function deleteNodeOwnerItem(bytes32 node, bytes32 item_key) external;
    function deleteNodeItemBatch(bytes32 node, bytes32[] memory item_keys) external;
    function deleteOwnerItemBatch(address owner, bytes32[] memory item_keys) external;

    function deleteNode(bytes32 node) external;
    function deleteReverse(address main_address) external;

    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);
    function isNodeValid(bytes32 node) external view returns (bool);

    function clearNode(bytes32 node) external;
    function createNode(bytes32 parent, bytes32 node, address owner, uint64 expire, bool locked) external;
    function transferNodeOwner(bytes32 node, address new_owner) external;

    function setTokenApprovals(uint256 token_id, address to) external;
    function setOperatorApprovals(address owner, address operator, bool approved) external;

    function tokenApprovals(uint256 token_id) external view returns (address);
    function operatorApprovals(address owner, address operator) external view returns (bool);

    function rootNode() external view returns (bytes32);

    function checkNode(bytes32 node) external view returns (bool);

}


