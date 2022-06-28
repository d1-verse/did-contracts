
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./KeyDefinition.sol";

abstract contract KVStorage is KeyDefinition { // KVS: Key Value Storage

    function abiBytesToAddress(bytes memory bys) public pure returns(address payable ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (address));
        }
        return ret;
    }

    function abiBytesToUint64(bytes memory bys) public pure returns(uint64 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint64));
        }
        return ret;
    }

    function abiBytesToUint256(bytes memory bys) public pure returns(uint256 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint256));
        }
        return ret;
    }

    function abiBytesToString(bytes memory bys) public pure returns(string memory ret) {
        if (bys.length > 0) {
            ret = abi.decode(bys, (string));
        }
        return ret;
    }

    function encodeItemKey(bytes32 node, uint256 item_key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, bytes32(item_key)));
    }

    function encodeNameToNode(bytes32 parent, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    function getNodeOwner(bytes32 node) public view returns (address) {
        return _coreDB.getNodeOwner(node);
    }

    function getRegistrar(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(_coreDB.getNodeItem(node, bytes32(KEY_REGISTRAR)));
    }

    function getManager(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, KEY_MANAGER)));
    }

    function getMainAddress(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(_coreDB.getNodeOwnerItem(node, encodeItemKey(node, KEY_ADDRESS_MAIN)));
    }

    function abiBytesToAddressWithoutTimestamp(bytes memory bys) public pure returns(address payable addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
    }

}


