// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {ERC5006} from "../src/ERC5006.sol";

contract ERC5006Script is Script {
    ERC5006 public rentalNft;

    function setUp() public {}
    function run() public {
        rentalNft = new ERC5006("Kaia-test-Nft", "KTN", "", type(uint256).max);
        console.log(address(rentalNft));
    }
}
