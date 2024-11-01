// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {ERC4907} from "../src/ERC4907.sol";

contract ERC4907Script is Script {
    ERC4907 public rentalNft;

    function setUp() public {}
    function run() public {
        rentalNft = new ERC4907("Kaia-test-Nft", "KTN");
        console.log(address(rentalNft));
    }
}
