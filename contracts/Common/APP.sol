
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ICoreDB.sol";

abstract contract APP {

    ICoreDB internal _coreDB;

    mapping(address => bool) internal _operators;

    modifier onlyCoreDAO {
        require(msg.sender == _coreDB.coreDAO(), "Caller is not the CoreDAO");
        _;
    }

    modifier onlyOperator {
        require(isOperator(msg.sender) , "Caller is not an operator");
        _;
    }

    modifier onlyCoreNFT {
        require(msg.sender == _coreDB.coreNFT(), "Caller is not the CoreNFT");
        _;
    }

    modifier onlyCoreRegistrar {
        require(msg.sender == _coreDB.coreRegistrar(), "Caller is not the CoreRegistrar");
        _;
    }

    function initApp(address core_db, bool dao_is_operator) internal {
        _coreDB = ICoreDB(core_db);
        if (dao_is_operator) {
            _operators[_coreDB.coreDAO()] = true;
        }
    }

    function setCoreDB(address core_db) external onlyCoreDAO {
        _coreDB = ICoreDB(core_db);
    }

    function setOperator(address addr, bool flag) external onlyCoreDAO {
        _operators[addr] = flag;
    }

    function isOperator(address addr) public view returns (bool) {
        return _operators[addr];
    }

}


