
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/KVStorage.sol";
import "./Common/ICoreDB.sol";

interface ICoreNFT {
    function beforeMint(address to, uint256 tokenId) external;
    function afterMint(address to, uint256 tokenId, bytes memory _data) external;
    function reclaimNFT(address from, address to, uint256 tokenId, bytes memory _data) external;
}

interface ISensitiveWords {
    function sensitiveHash(bytes32 word_hash) external view returns (bool);
    function sensitiveWord(string memory word) external view returns (bool);
    function checkedWord(string memory word) external pure returns (bool);
    function validWord(string memory word) external view returns (bool);
}

contract CoreRegistrar is KVStorage {

    event NodeCreatedOrReclaimed(bytes32 indexed parent, bytes32 indexed node, address indexed owner, uint64 expire, uint64 ttl, address payment, uint256 cost, string name);
    // event NodeItemChanged(bytes32 indexed node, address indexed owner, bytes32 indexed key);
    event NodeItemChangedWithValue(bytes32 indexed node, address indexed owner, bytes32 indexed key, bytes value);
    // event NodeOwnerItemChanged(bytes32 indexed node, address indexed owner, bytes32 indexed key);
    event NodeOwnerItemChangedWithValue(bytes32 indexed node, address indexed owner, bytes32 indexed key, bytes value);
    event NodeExpireUpdated(bytes32 indexed node, address indexed owner, uint64 expire);
    event ReverseRecordSet(address indexed main_address, bytes32 indexed node); // node == bytes32(0), means ReverseRecordDeleted

    mapping(address => bool) public tldRegistrars; // Top Level Domain Registrars
    bool public openForAll;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    constructor(address core_db) {
        initApp(core_db, true);
        openForAll = true;
    }

    // Require msg.sender is a TeamMember (Owner, Manager, Main_Address, Registrar_Contract)
    modifier onlyTeamMemberAndActive(bytes32 node) {
        require (
            msg.sender == getNodeOwner(node) ||
            msg.sender == getRegistrar(node) ||
            msg.sender == getMainAddress(node) ||
            msg.sender == getManager(node),
            "Caller is not a team member"
        );
        require (_coreDB.isNodeValid(node), "Node is invalid");
        _;
    }

    modifier onlyTldRegistrar() {
        require(tldRegistrars[msg.sender], "The caller is not verse-registrar");
        _;
    }

    function setOpenForAll(bool flag) external onlyOperator {
        openForAll = flag;
    }

    function setWeb2(bytes32 node, uint256 web2_type, bytes memory web2_info) external onlyTldRegistrar {
        require(web2_type == KEY_TWITTER || web2_type == KEY_INSTAGRAM, "This web2 type is not supported");
        // address main_address = getMainAddress(node);
        address owner = _coreDB.getNodeOwner(node);
        _coreDB.setOwnerItem(owner, encodeItemKey(node, web2_type), web2_info);
        emit NodeOwnerItemChangedWithValue(node, owner, bytes32(web2_type), web2_info);
    }

    function setWeb3(address main_address_or_owner, uint256 web3_type, bytes memory we3_info) external onlyTldRegistrar {
        require(web3_type == KEY_KEY_VOICE_SCORE, "This web3 type is not supported");
        _coreDB.setOwnerItem(main_address_or_owner, encodeItemKey(bytes32(0), web3_type), we3_info);
        emit NodeOwnerItemChangedWithValue(bytes32(0), main_address_or_owner, bytes32(web3_type), we3_info);
    }

    function setTTL(bytes32 node, uint64 ttl) external onlyTeamMemberAndActive(node) {
        _setNodeItem(node, bytes32(KEY_TTL), abi.encode(ttl));
    }

    function setNftMetadataURI(bytes32 node, string memory uri) external onlyTeamMemberAndActive(node) {
        _setNodeItem(node, bytes32(KEY_NFT_METADATA_URI), abi.encode(uri));
    }

    function _setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) private {
        _coreDB.setNodeItem(node, item_key, item_value);
        emit NodeItemChangedWithValue(node, getNodeOwner(node), item_key, item_value);
    }

    // Registrar or Resolver is node-item, not owner-item
    function setRegistrar(bytes32 node, address registrar) external onlyTeamMemberAndActive(node) {
        _setNodeItem(node, bytes32(KEY_REGISTRAR), abi.encode((uint256(uint160(registrar)) << 96) + uint64(block.timestamp)));
        if (_coreDB.getNodeParent(node) == _coreDB.rootNode()) { // Only record Top Level Domain Registrar
            delete tldRegistrars[getRegistrar(node)];
            tldRegistrars[registrar] = true;
        }
    }

    // Registrar or Resolver is node-item, not owner-item
    function setResolver(bytes32 node, address resolver) external onlyTeamMemberAndActive(node) {
        _setNodeItem(node, bytes32(KEY_RESOLVER), abi.encode((uint256(uint160(resolver)) << 96) + uint64(block.timestamp)));
    }

    function setManager(bytes32 node, address manager) public onlyTeamMemberAndActive(node) {
        _setNodeOwnerAddressItem(node, KEY_MANAGER, manager);
    }

    function setMainAddress(bytes32 node, address main_address) public onlyTeamMemberAndActive(node) {
        address old_main_address = _deleteReverseWithNode(node);
        require(old_main_address != main_address, "main_address is already set");
        _setNodeOwnerAddressItem(node, KEY_ADDRESS_MAIN, main_address);
        // if (_coreDB.getReverse(main_address) == bytes32(0)) {
        //    _coreDB.setReverse(main_address, node);
        // }
        // to support "setReverse" sentence above, need stricter check: require main_address's signature, to avoid set orther users' address
        // function setMainAddress(bytes32 node, address main_address, bytes memory signautre_of_main_address) public onlyTeamMemberAndActive(node) {...}
        // 1) setMainAddress; 2) setReverse
    }

    function setReverse(bytes32 node) external {
        address main_address = msg.sender;
        require(getMainAddress(node) == main_address, "node and main address (msg.sender) do not match");
        _coreDB.setReverse(main_address, node);
        emit ReverseRecordSet(main_address, node);
    }

    function setReverseWithNode(bytes32 node, address owner) external onlyCoreNFT {
        _resetNode(node, owner);
    }

    function _resetNode(bytes32 node, address owner) private {
        _setNodeOwnerAddressItem(node, KEY_MANAGER, owner);
        _setNodeOwnerAddressItem(node, KEY_ADDRESS_MAIN, owner);
        if (_coreDB.reverseRecord(owner) == bytes32(0)) {
            _coreDB.setReverse(owner, node);
            emit ReverseRecordSet(owner, node);
        }
    }

    function deleteReverse() external {
        bytes32 node = _coreDB.reverseRecord(msg.sender);
        if (node != bytes32(0)) {
            _coreDB.deleteReverse(msg.sender);
            emit ReverseRecordSet(msg.sender, bytes32(0));
        }
    }

    function deleteReverseWithNode(bytes32 node) external onlyCoreNFT {
        _deleteReverseWithNode(node);
    }

    function _deleteReverseWithNode(bytes32 node) private returns (address) {
        address main_address = getMainAddress(node);
        if (_coreDB.reverseRecord(main_address) == node) {
            _coreDB.deleteReverse(main_address);
            emit ReverseRecordSet(main_address, bytes32(0));
        }
        return main_address;
    }

    function setEthLikeAddress(bytes32 node, uint256[] memory item_keys, address[] memory eth_like_addrs) external onlyTeamMemberAndActive(node) {
        require(item_keys.length == eth_like_addrs.length, "Length error");
        for (uint256 i=0; i < item_keys.length; i++) {
            require(item_keys[i] >= ETHEREUM_LIKE_ADDRESS_BEGIN && item_keys[i] <= ETHEREUM_LIKE_ADDRESS_END, "Item key is not an ethereum-like address");
            if (item_keys[i] == KEY_ADDRESS_MAIN) {
                setMainAddress(node, eth_like_addrs[i]);
            } else {
                _setNodeOwnerAddressItem(node, item_keys[i], eth_like_addrs[i]);
            }
        }
    }

    function _setNodeOwnerAddressItem(bytes32 node, uint256 item_key, address addr) private {
        bytes32 encoded_item_key = encodeItemKey(node, item_key);
        bytes memory encoded_item_value = "";
        address owner = _coreDB.getNodeOwner(node);
        if (addr == address(0)) {
            _coreDB.deleteOwnerItem(owner, encoded_item_key);
        } else {
            // Address with Timestamp: |Address(160bit)|Null(32bit)|Timestamp(64bit)|
            encoded_item_value = abi.encode((uint256(uint160(addr)) << 96) + uint64(block.timestamp));
            _coreDB.setOwnerItem(owner, encoded_item_key, encoded_item_value);
        }
        emit NodeOwnerItemChangedWithValue(node, owner, bytes32(item_key), encoded_item_value);
    }

    // The caller should make sure: require(parent is existed)
    function isExpireValid(bytes32 parent, uint64 expire) public view returns (bool) {
        return _coreDB.getNodeExpire(parent) >= expire && expire > block.timestamp;
    }

    // Alice -> CoreRegistrar.setSubnodeRecord -> CoreDB.createNodeRecord -> NFT.afterMint
    // Bob -> Alice.Registrar -> CoreRegistrar.registerSubnode -> CoreDB.createNodeRecord -> NFT.afterMint
    function registerSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        address payment,
        uint256 cost,
        string memory name,
        bytes memory _data
    ) external nonReentrant() onlyTeamMemberAndActive(parent) returns (bytes32) {
        // require(_coreDB.checkNode(parent), "Parent Node is not available");
        require(openForAll || tldRegistrars[msg.sender], "The caller is not verse-registrar");
        require(owner != address(0) , "Owner is address(0)");
        require(isExpireValid(parent, expire), "Expire is invalid");

        address core_sw = _coreDB.coreSW();
        if (core_sw != address(0)) {
            require(ISensitiveWords(core_sw).validWord(name), "Name is sensitive or not checked");
        }

        bytes32 node = encodeNameToNode(parent, name);
        // require(node != parent, "Node is same as parent"); // useless

        address nft = _coreDB.coreNFT();
        if (!_coreDB.isNodeExisted(node)) {
            _coreDB.createNode(parent, node, owner, expire, false);
            ICoreNFT(nft).afterMint(owner, uint256(node), _data); // _resetNode(node, owner);
        } else if (!_coreDB.isNodeActive(node)) {
            ICoreNFT(nft).reclaimNFT(_coreDB.getNodeOwner(node), owner, uint256(node), _data);
            _coreDB.setNodeExpire(node, expire);
        } else {
            revert("The node is active");
        }

        _coreDB.setNodeItem(node, bytes32(KEY_TTL), abi.encode(ttl));
        _coreDB.setNodeItem(node, bytes32(KEY_NAME), abi.encode(name));

        emit NodeCreatedOrReclaimed(parent, node, owner, expire, ttl, payment, cost, name);

        return node;

    }

    function renewExpire(bytes32 node, uint64 new_expire) external {
        bytes32 parent = _coreDB.getNodeParent(node);
        require(msg.sender == getRegistrar(parent), "Caller is not the registrar of the parent node");
        require(isExpireValid(parent, new_expire), "Expire is invalid");
        _coreDB.setNodeExpire(node, new_expire);
    }


}


// ICoreNFT(nft).beforeMint(owner, uint256(node)); // need not to call beforeMint
// emit NodeItemChangedWithValue(node, owner, bytes32(KEY_TTL), abi.encode(ttl));
// emit NodeItemChangedWithValue(node, owner, bytes32(KEY_NAME), abi.encode(name));
// NFT transfer require DID(Node) not expired for normal case to avoid some fraud; but allow transferring if Msg.sender == CoreUI


