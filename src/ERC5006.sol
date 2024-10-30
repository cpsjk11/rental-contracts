// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.25;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IERC5006.sol";

contract ERC5006 is ERC1155, ERC1155Holder, IERC5006 {
    using EnumerableSet for EnumerableSet.UintSet;
    mapping(uint256 => mapping(address => uint256)) private _frozens;
    mapping(uint256 => UserRecord) private _records;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet))
        private _userRecordIds;
    uint256 _curRecordId;
    uint256 recordLimit;

    constructor(string memory uri_, uint256 recordLimit_) ERC1155(uri_) {
        recordLimit = recordLimit_;
    }

    function isOwnerOrApproved(address owner) public view returns (bool) {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "only owner or approved"
        );
        return true;
    }

    function usableBalanceOf(
        address account,
        uint256 tokenId
    ) public view override returns (uint256 amount) {
        uint256[] memory recordIds = _userRecordIds[tokenId][account].values();
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (block.timestamp <= _records[recordIds[i]].expiry) {
                amount += _records[recordIds[i]].amount;
            }
        }
    }

    function frozenBalanceOf(
        address account,
        uint256 tokenId
    ) public view override returns (uint256) {
        return _frozens[tokenId][account];
    }

    function userRecordOf(
        uint256 recordId
    ) public view override returns (UserRecord memory) {
        return _records[recordId];
    }

    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint64 amount,
        uint64 expiry
    ) public override returns (uint256) {
        require(isOwnerOrApproved(owner));
        require(user != address(0), "user cannot be the zero address");
        require(amount > 0, "amount must be greater than 0");
        require(
            expiry > block.timestamp,
            "expiry must after the block timestamp"
        );
        require(
            _userRecordIds[tokenId][user].length() < recordLimit,
            "user cannot have more records"
        );
        _safeTransferFrom(owner, address(this), tokenId, amount, "");
        _frozens[tokenId][owner] += amount;
        _curRecordId++;
        _records[_curRecordId] = UserRecord(
            tokenId,
            owner,
            amount,
            user,
            expiry
        );
        _userRecordIds[tokenId][user].add(_curRecordId);
        emit CreateUserRecord(
            _curRecordId,
            tokenId,
            amount,
            owner,
            user,
            expiry
        );
        return _curRecordId;
    }

    function deleteUserRecord(uint256 recordId) public override {
        UserRecord storage _record = _records[recordId];
        require(isOwnerOrApproved(_record.owner));
        _safeTransferFrom(
            address(this),
            _record.owner,
            _record.tokenId,
            _record.amount,
            ""
        );
        _frozens[_record.tokenId][_record.owner] -= _record.amount;
        _userRecordIds[_record.tokenId][_record.user].remove(recordId);
        delete _records[recordId];
        emit DeleteUserRecord(recordId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC1155Holder) returns (bool) {
        return
            interfaceId == type(IERC5006).interfaceId ||
            ERC1155.supportsInterface(interfaceId);
    }
}
