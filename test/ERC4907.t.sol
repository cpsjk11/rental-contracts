// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ERC4907} from "../src/ERC4907.sol";

contract ERC4907Test is Test {
    uint256 public privateKey = uint256(keccak256("owner"));
    address public owner = vm.addr(privateKey);
    ERC4907 public nft;

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.label(owner, "Owner");

        vm.startPrank(owner);
        nft = new ERC4907("Test NFT", "TN");
        console.log(address(nft));
        vm.label(address(nft), "Rental NFT");
    }

    function test_mintToSetUser() public {
        nft.mint(owner, 1);

        address nftOwner = nft.ownerOf(1);
        uint256 balance = nft.balanceOf(owner);

        assertEq(owner, nftOwner);
        assertEq(balance, 1);

        nft.approve(makeAddr("bob"), 1);
        nft.setUser(1, makeAddr("bob"), 600);

        address rentalUser = nft.userOf(1);
        uint256 expires = nft.userExpires(1);

        assertEq(makeAddr("bob"), rentalUser);
        assertEq(600, expires);
    }

    function test_timeOverRental() public {
        address bob = makeAddr("bob");
        nft.mint(owner, 1);

        nft.approve(bob, 1);

        nft.setUser(1, bob, 100);

        uint256 expires = nft.userExpires(1);
        address rentalUser = nft.userOf(1);

        assertEq(expires, 100);
        assertEq(rentalUser, bob);

        vm.warp(86400);

        uint256 nextDayExpires = nft.userExpires(1);
        address nextDayRentalUser = nft.userOf(1);

        assertEq(100, nextDayExpires);
        assertEq(address(0), nextDayRentalUser);
    }
}
