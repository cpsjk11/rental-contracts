// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract PoplusERC1155 is ERC1155 {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function setURI(string memory uri) public {
        super._setURI(uri);
    }

    function mint(address to, uint256 id, uint256 amount) public {
        super._mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) public {
        super._mintBatch(to, ids, values, "");
    }
}
