
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/ICoreDB.sol";
import "./Common/APP.sol";

contract CoreDB is ICoreDB, APP {

    mapping(address => mapping(bytes32 => bytes)) public ownerRecord;
    mapping(bytes32 => Node) public nodeRecord;
    mapping(address => bytes32) public reverseRecord;
    mapping(address => bool) public ownerLock;
    mapping(bytes32 => bool) public nodeLock;
    mapping(address => mapping(bytes32 => bool)) public ownerItemLock;
    mapping(bytes32 => mapping(bytes32 => bool)) public nodeItemLock;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(uint256 => address) public tokenApprovals; // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) public operatorApprovals;  // Mapping from owner to operator approvals

    bytes32 constant public rootNode = keccak256(abi.encodePacked("")); // ROOT_NODE

    address public coreDAO ;
    address public coreRegistrar;
    address public coreNFT;
    address public coreSW;
    address public coreDB;
    address public coreResolver;
    string public metadataURI;

    constructor(address core_dao) {
        coreDAO = core_dao;
        coreDB = address(this);
        nodeRecord[rootNode].parent = rootNode;
        nodeRecord[rootNode].owner = core_dao;
        nodeRecord[rootNode].expire = type(uint64).max;
        balanceOf[core_dao] = 1;
        totalSupply = 1;
        initApp(address(this), false);
    }

    modifier onlyExisted(bytes32 node) {
        require(isNodeExisted(node) , "The node is not existed");
        _;
    }

    function coreMeta() external view returns (address, address, address, address, address, address) {
        return (coreDAO, coreDB, coreRegistrar, coreResolver, coreNFT, coreSW);
    }

    function setMetadataURI(string memory uri) external onlyCoreDAO {
        metadataURI = uri;
    }

    function setCoreDAO(address dao) external onlyCoreDAO {
        coreDAO = dao;
    }

    function setCoreRegistrar(address registrar) public onlyCoreDAO {
        coreRegistrar = registrar;
        _operators[registrar] = true;
    }

    function setCoreNFT(address nft) public onlyCoreDAO {
        coreNFT = nft;
        _operators[nft] = true;
    }

    function setCoreSW(address sw) external onlyCoreDAO {
        coreSW = sw;
    }

    function setCoreResolver(address resolver) external onlyCoreDAO {
        coreResolver = resolver;
    }

    function _increaseBalance(address owner, uint256 amount) internal {
        balanceOf[owner] += amount;
    }

    function _decreaseBalance(address owner, uint256 amount) internal {
        balanceOf[owner] -= amount;
    }

    function _increaseTotalSupply(uint256 amount) internal {
        totalSupply += amount;
    }

    function _decreaseTotalSupply(uint256 amount) internal {
        totalSupply -= amount;
    }

    function increaseBalance(address owner, uint256 amount) external onlyOperator {
        _increaseBalance(owner, amount);
    }

    function decreaseBalance(address owner, uint256 amount) external onlyOperator {
        _decreaseBalance(owner, amount);
    }

    function increaseTotalSupply(uint256 amount) external onlyOperator {
        _increaseTotalSupply(amount);
    }

    function decreaseTotalSupply(uint256 amount) external onlyOperator {
        _decreaseTotalSupply(amount);
    }

    function setReverse(address main_address, bytes32 node) onlyExisted(node) external onlyOperator {
        reverseRecord[main_address] = node;
    }

    function deleteReverse(address main_address) external onlyOperator {
        delete reverseRecord[main_address];
    }

    function _initNode(bytes32 node, bytes32 parent, address owner, uint64 expire, bool locked) internal {
        nodeRecord[node].parent = parent;
        nodeRecord[node].owner = owner;
        nodeRecord[node].expire = expire;
        nodeLock[node] = locked;
    }

    function initNode(bytes32 node, bytes32 parent, address owner, uint64 expire, bool locked) external onlyOperator {
        _initNode(node, parent, owner, expire, locked);
    }

    function _deleteNode(bytes32 node) internal {
        // delete nodeRecord[node].db; // can not compile
        delete nodeRecord[node];
    }

    function deleteNode(bytes32 node) onlyExisted(node) external onlyOperator {
        _deleteNode(node);
    }

    function _setNodeOwner(bytes32 node, address owner) internal {
        nodeRecord[node].owner = owner;
    }

    function setNodeOwner(bytes32 node, address owner) external onlyExisted(node) onlyOperator {
        _setNodeOwner(node, owner);
    }

    function setNodeExpire(bytes32 node, uint64 expire) external onlyExisted(node) onlyOperator {
        nodeRecord[node].expire = expire;
    }

    function lockNode(bytes32 node, bool locked) external onlyExisted(node) onlyOperator {
        nodeLock[node] = locked;
    }

    function lockNodeItem(bytes32 node, bytes32 item_key, bool locked) external onlyExisted(node) onlyOperator {
        nodeItemLock[node][item_key] = locked;
    }

    function lockOwner(address owner, bool locked) external onlyOperator {
        ownerLock[owner] = locked;
    }

    function lockOwnerItem(address owner, bytes32 item_key, bool locked) external onlyOperator {
        ownerItemLock[owner][item_key] = locked;
    }

    function setOwnerItem(address owner, bytes32 item_key, bytes memory item_value) external onlyOperator {
        ownerRecord[owner][item_key] = item_value;
    }

    function deleteOwnerItem(address owner, bytes32 item_key) external onlyOperator {
        delete ownerRecord[owner][item_key];
    }

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external onlyExisted(node) onlyOperator {
        nodeRecord[node].db[item_key] = item_value;
    }

    function setNodeOwnerItem(bytes32 node, bytes32 item_key, bytes memory item_value) external onlyExisted(node) onlyOperator {
        ownerRecord[getNodeOwner(node)][item_key] = item_value;
    }

    function deleteNodeItem(bytes32 node, bytes32 item_key) external onlyExisted(node) onlyOperator {
        delete nodeRecord[node].db[item_key];
    }

    function deleteNodeOwnerItem(bytes32 node, bytes32 item_key) external onlyExisted(node) onlyOperator {
        delete ownerRecord[getNodeOwner(node)][item_key];
    }

    function getOwnerItem(address owner, bytes32 item_key) public view returns (bytes memory) {
        return ownerRecord[owner][item_key];
    }

    function getOwnerItemLength(address owner, bytes32 item_key) public view returns (uint256) {
        return ownerRecord[owner][item_key].length;
    }

    function getNodeItem(bytes32 node, bytes32 item_key) public onlyExisted(node) view returns (bytes memory) {
        return nodeRecord[node].db[item_key];
    }

    function getNodeOwnerItem(bytes32 node, bytes32 item_key) public onlyExisted(node) view returns (bytes memory) {
        return getOwnerItem(getNodeOwner(node), item_key);
    }

    function getNodeItemLength(bytes32 node, bytes32 item_key) public onlyExisted(node) view returns (uint256) {
        return nodeRecord[node].db[item_key].length;
    }

    function getNodeOwnerItemLength(bytes32 node, bytes32 item_key) public onlyExisted(node) view returns (uint256) {
        return getNodeOwnerItem(node, item_key).length;
    }

    function getNodeParent(bytes32 node) public view returns (bytes32) {
        return (nodeRecord[node].parent);
    }

    function getNodeOwner(bytes32 node) public view returns (address) {
        return (nodeRecord[node].owner);
    }

    function getNodeExpire(bytes32 node) public view returns (uint64) {
        return (nodeRecord[node].expire);
    }

    function isNodeValid(bytes32 node) public view returns (bool) {
        return !nodeLock[node] && nodeRecord[node].expire >= block.timestamp;
    }

    function isNodeActive(bytes32 node) public view returns (bool) {
        return nodeRecord[node].expire >= block.timestamp;
    }

    function isNodeExisted(bytes32 node) public view returns (bool) {
        return nodeRecord[node].parent != bytes32(0);
    }

    function checkNode(bytes32 node) public view onlyExisted(node) returns (bool) {
        bool active = isNodeActive(node);
        if (active) {
            require(!nodeLock[node], "Node is locked");
        }
        return active;
    }

    function createNode(bytes32 parent, bytes32 node, address owner, uint64 expire, bool locked) external onlyCoreRegistrar {
        require(!isNodeExisted(node), "Node is existed");
        _initNode(node, parent, owner, expire, locked);
        _increaseBalance(owner, 1);
        _increaseTotalSupply(1);
    }

    // Transfer NFT // checkNode requires onlyExisted(node)
    function transferNodeOwner(bytes32 node, address new_owner) external onlyCoreNFT {
        checkNode(node);
        _decreaseBalance(getNodeOwner(node), 1);
        _increaseBalance(new_owner, 1);
        _setNodeOwner(node, new_owner);
    }

    // Burn NFT // checkNode requires onlyExisted(node)
    function clearNode(bytes32 node) external onlyCoreNFT {
        checkNode(node);
        _decreaseBalance(getNodeOwner(node), 1);
        _decreaseTotalSupply(1);
        _deleteNode(node);
    }

    function setTokenApprovals(uint256 token_id, address to) external onlyExisted(bytes32(token_id)) onlyCoreNFT {
        tokenApprovals[token_id] = to;
    }

    function setOperatorApprovals(address owner, address operator, bool approved) external onlyCoreNFT {
        operatorApprovals[owner][operator] = approved;
    }

    function lockNodeBatch(bytes32[] memory nodes, bool locked) external onlyOperator {
        for (uint256 i=0; i < nodes.length; i++) {
            if (isNodeExisted(nodes[i])) {
                nodeLock[nodes[i]] = locked;
            }
        }
    }

    function lockNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bool locked) external onlyExisted(node) onlyOperator {
        for (uint256 i=0; i < item_keys.length; i++) {
            nodeItemLock[node][item_keys[i]] = locked;
        }
    }

    // checkNode requires onlyExisted(node)
    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external onlyOperator {
        require(item_keys.length == item_values.length, "Length error");
        bool active = checkNode(node);
        for (uint256 i=0; i < item_keys.length; i++) {
            require(!active || !nodeItemLock[node][item_keys[i]], "Owner item is locked");
            nodeRecord[node].db[item_keys[i]] = item_values[i];
        }
    }

    // checkNode requires onlyExisted(node)
    function deleteNodeItemBatch(bytes32 node, bytes32[] memory item_keys) external onlyOperator {
        bool active = checkNode(node);
        for (uint256 i=0; i < item_keys.length; i++) {
            require(!active || !nodeItemLock[node][item_keys[i]], "Owner item is locked");
            delete nodeRecord[node].db[item_keys[i]];
        }
    }

    function lockOwnerBatch(address[] memory owners, bool locked) external onlyOperator {
        for (uint256 i=0; i < owners.length; i++) {
            ownerLock[owners[i]] = locked;
        }
    }

    function setOwnerItemBatch(address owner, bytes32[] memory item_keys, bytes[] memory item_values) external onlyOperator {
        require(item_keys.length == item_values.length, "Length error");
        require(!ownerLock[owner], "Owner is locked");
        for (uint256 i=0; i < item_keys.length; i++) {
            require(!ownerItemLock[owner][item_keys[i]], "Owner item is locked");
            ownerRecord[owner][item_keys[i]] = item_values[i];
        }
    }

    function deleteOwnerItemBatch(address owner, bytes32[] memory item_keys) external onlyOperator {
        require(!ownerLock[owner], "Owner is locked");
        for (uint256 i=0; i < item_keys.length; i++) {
            require(!ownerItemLock[owner][item_keys[i]], "Owner item is locked");
            delete ownerRecord[owner][item_keys[i]];
        }
    }

    function lockOwnerItemBatch(address owner, bytes32[] memory item_keys, bool locked) external onlyOperator {
        for (uint256 i=0; i < item_keys.length; i++) {
            ownerItemLock[owner][item_keys[i]] = locked;
        }
    }

}

