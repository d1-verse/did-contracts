
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


import "./Common/APP.sol";
import "./Common/LibSignature.sol";
import "./Common/KeyDefinition.sol";

interface IResolver {
    function getKeyVoiceScore(address main_address) external view returns (uint256);
    function getNodeName(bytes32 node) external view returns (string memory);
    // function getMainAddress(bytes32 node) external view returns (address);
    function getNodeOwner(bytes32 node) external view returns (address);
}

interface IRegistrar {
    function registerSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        address payment,
        uint256 cost,
        string memory name,
        bytes memory _data
    ) external returns (bytes32);
    function setWeb2(bytes32 node, uint256 web2_type, bytes memory we2_info) external;
    function setWeb3(address main_address, uint256 web3_type, bytes memory we3_info) external;
}

contract VerseRegistrar is KeyDefinition {

    using LibSignature for bytes32;

    bytes32 public TOP_LEVEL_NODE = 0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa; // verse node
    uint256 public FREE_REGISTRATION_DURATION = 365 days;
    address public platform;
    uint64 public interval = 300;
    uint64 public default_ttl = 300;

    constructor(address core_db) {
        initApp(core_db, true);
    }

    function setPlatform(address platform_address) external onlyOperator {
        platform = platform_address;
    }

    function setInterval(uint64 interval_seconds) external onlyOperator {
        interval = interval_seconds;
    }

    function setDefaultTTL(uint64 ttl) external onlyOperator {
        default_ttl = ttl;
    }

    function setFreeDuration(uint256 duration) external onlyOperator {
        FREE_REGISTRATION_DURATION = duration;
    }

    function setKeyVoiceScore(address main_address, uint256 score, bytes memory signature) external {
        verify_kvs_signature(main_address, score, signature);
        require(score > IResolver(_coreDB.coreResolver()).getKeyVoiceScore(main_address), "The score is not greater than current score");
        IRegistrar(_coreDB.coreRegistrar()).setWeb3(main_address, KEY_KEY_VOICE_SCORE, abi.encode(score));
    }

    function setTwitter(bytes32 node, string memory twitter_name, bytes memory signature) external {
        verify_name_signature(IResolver(_coreDB.coreResolver()).getNodeOwner(node), "", twitter_name, KEY_TWITTER, signature);
        IRegistrar(_coreDB.coreRegistrar()).setWeb2(node, KEY_TWITTER, abi.encode(twitter_name));
    }

    function setInstagram(bytes32 node, string memory instagram_name, bytes memory signature) external {
        verify_name_signature(IResolver(_coreDB.coreResolver()).getNodeOwner(node), "", instagram_name, KEY_INSTAGRAM, signature);
        IRegistrar(_coreDB.coreRegistrar()).setWeb2(node, KEY_INSTAGRAM, abi.encode(instagram_name));
    }

    function register(
        address owner,
        uint64 ttl,
        string memory name,
        bytes memory signature
    ) external returns (bytes32) {
        uint64 expire = uint64(block.timestamp + FREE_REGISTRATION_DURATION);
        verify_name_signature(owner, name, "", 0, signature);
        bytes32 node = IRegistrar(_coreDB.coreRegistrar()).registerSubnode(TOP_LEVEL_NODE, owner, expire, ttl,  address(0), 0, name, "");
        return node;
    }

    function registerWithWeb2(
        address owner,
        uint64 ttl,
        uint256 web2_type,
        string memory web2_name,
        string memory name,
        bytes memory signature
    ) external returns (bytes32) {
        uint64 expire = uint64(block.timestamp + FREE_REGISTRATION_DURATION);
        verify_name_signature(owner, name, web2_name, web2_type, signature);
        IRegistrar coreRegistrar = IRegistrar(_coreDB.coreRegistrar());
        bytes32 node = coreRegistrar.registerSubnode(TOP_LEVEL_NODE, owner, expire, ttl,  address(0), 0, name, "");
        coreRegistrar.setWeb2(node, web2_type, abi.encode(web2_name));
        return node;
    }

    function verify_name_signature(address main_address, string memory name, string memory web2_name, uint256 web2_type, bytes memory signature) public view {
        bytes memory preimage = abi.encode(block.timestamp / interval, main_address, web2_type, web2_name, name);
        verify(preimage, signature);
    }

    function verify_kvs_signature(address main_address, uint256 score, bytes memory signature) public view {
        bytes memory preimage = abi.encode(block.timestamp / interval, main_address, KEY_KEY_VOICE_SCORE, score);
        verify(preimage, signature);
    }

    function verify(bytes memory preimage, bytes memory signature) private view {
        if (platform != address(0) ) {
            bytes32 hash = keccak256(preimage);
            address signer = hash.recover(signature);
            require(signer == platform, "Name should be verified by the platform");
        }
    }

    function registerAirDrop(address[] memory owners, string[] memory names) external onlyOperator {
        require(owners.length == names.length, "Length error");
        IRegistrar coreRegistrar = IRegistrar(_coreDB.coreRegistrar());
        uint64 expire = uint64(block.timestamp + FREE_REGISTRATION_DURATION);
        for (uint256 i = 0; i < owners.length; i++) {
            coreRegistrar.registerSubnode(TOP_LEVEL_NODE, owners[i], expire, default_ttl,  address(0), 0, names[i], "");
        }
    }

}



