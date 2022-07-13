
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// https://eips.ethereum.org/EIPS/eip-721
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol"

import "./Common/APP.sol";

interface IMetadata {
    function getNftMetadataURI(bytes32 node) external view returns (string memory);
}

interface IReverse {
    function setReverse(bytes32 node) external;
    function setReverseWithNode(bytes32 node, address owner) external;
    function deleteReverse() external;
    function deleteReverseWithNode(bytes32 node) external;
}

contract CoreNFT is IERC721Metadata, APP {

    using Address for address;
    using Strings for uint256;

    string public name;
    string public symbol;
    string public baseURI;
    bool public personalURI;

    // mapping(uint256 => address) private _tokenApprovals; // Mapping from token ID to approved address
    // mapping(address => mapping(address => bool)) private _operatorApprovals;  // Mapping from owner to operator approvals

    constructor(address core_db, string memory nft_name, string memory nft_symbol, string memory base_uri) {
        initApp(core_db, true);
        name = nft_name;
        symbol = nft_symbol;
        baseURI = base_uri;
    }

    function setName(string calldata new_name) public onlyCoreDAO {
        name = new_name;
    }

    function setSymbol(string calldata new_symbol) public onlyCoreDAO {
        symbol = new_symbol;
    }

    function setBaseURI(string memory base_uri) public onlyCoreDAO {
        baseURI = base_uri;
    }

    function setPersonalURI(bool personal_uri) public onlyOperator {
        personalURI = personal_uri;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        string memory uri = IMetadata(_coreDB.coreResolver()).getNftMetadataURI(bytes32(tokenId));
        if (personalURI && bytes(uri).length > 0) {
            return uri;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _coreDB.getNodeOwner(bytes32(tokenId));
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _coreDB.balanceOf(owner);
    }

    function totalSupply() public view returns (uint256) {
        return _coreDB.totalSupply();
    }

    function getApproved(uint256 tokenId) public view  returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _coreDB.tokenApprovals(tokenId); // _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        return _coreDB.operatorApprovals(owner, operator); // _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _coreDB.setTokenApprovals(tokenId, to); // _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _coreDB.setOperatorApprovals(owner, operator, approved); // _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        bytes32 node = bytes32(tokenId);
        address core_registrar = _coreDB.coreRegistrar();
        if (_msgSender() != core_registrar) {
            require(_coreDB.isNodeActive(node), "The node is not active, only core registrar can transfer it");
        }
        _approve(address(0), tokenId); // Clear approvals from the previous owner
        IReverse(core_registrar).deleteReverseWithNode(node);
        _coreDB.transferNodeOwner(node, to);
        IReverse(core_registrar).setReverseWithNode(node, to);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function reclaimNFT(address from, address to, uint256 tokenId, bytes memory _data) external {
        require(_msgSender() == _coreDB.coreRegistrar(), "ERC721: caller is not Core UI");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // 若节点处于过期待回收状态，_exists 仍可正常返回其 true，但 owner 执行转账会失败
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _coreDB.isNodeExisted(bytes32(tokenId));
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function beforeMint(address to, uint256 tokenId) external view onlyCoreRegistrar {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already existed");
    }

    function afterMint(address to, uint256 tokenId, bytes memory _data) external onlyCoreRegistrar {
        _approve(address(0), tokenId); // Clear approvals from the previous owner
        IReverse(_msgSender()).setReverseWithNode(bytes32(tokenId), to);
        emit Transfer(address(0), to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: mint to non ERC721Receiver implementer");
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: burn caller is not owner nor approved");
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        _coreDB.clearNode(bytes32(tokenId));
        emit Transfer(owner, address(0), tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC165).interfaceId;
    }

}


