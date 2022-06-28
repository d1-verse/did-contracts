
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/APP.sol";

contract SensitiveWords is APP {

    mapping(bytes32 => bool) public sensitiveHash;
    uint8 public minWordLength = 4;
    uint8 public maxWordLength = 14;

    constructor(address core_db) {
        initApp(core_db, true);
    }

    function setWordLength(uint8 min_len, uint8 max_len) external onlyOperator {
        require(max_len >= min_len, "Max word length should be greater than min word length");
        minWordLength = min_len;
        maxWordLength = max_len;
    }

    function putSensitiveHashBatch(bytes32[] memory hash_list, bool flag) external onlyOperator {
        for (uint256 i = 0; i < hash_list.length; i++) {
            sensitiveHash[hash_list[i]] = flag;
        }
    }

    function sensitiveWord(string memory word) public view returns (bool) {
        return sensitiveHash[keccak256(abi.encodePacked(word))];
    }

    function digitalOrAlphabet(uint8 character) internal pure returns (bool) {
        return (character >= 0x61 && character <= 0x7a) || (character >= 0x30 && character <= 0x39);
        // a ~ z || 0 ~ 9
    }

    function checkedWord(string memory word) public view returns (bool) {
        bytes memory word_bytes = bytes(word);

        if (word_bytes.length < minWordLength || word_bytes.length > maxWordLength) {
            return false;
        }

        for (uint256 i=0; i < word_bytes.length ; i++) {
            if (!digitalOrAlphabet(uint8(word_bytes[i]))) {
                return false;
            }
        }

        return true;
    }

    function validWord(string memory word) external view returns (bool) {
        return !sensitiveWord(word) && checkedWord(word);
    }

/**
    function isCheckedName(string memory name) external pure returns (bool) {
        bytes memory word_bytes = bytes(name);
        if (word_bytes.length < 4 || word_bytes.length > 14) {
            return false;
        }

        for (uint256 i=0; i < word_bytes.length ; i++) {
            if (uint8(word_bytes[i]) < 0x30 || uint8(word_bytes[i]) > 0x7a) {
                return false;
            }
            if (uint8(word_bytes[i]) > 0x39 && uint8(word_bytes[i]) < 0x61) {
                return false;
            }
        }

        return true;
    }
 */

}


