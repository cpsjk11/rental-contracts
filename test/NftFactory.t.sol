// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {NftFactory} from "../src/NftFactory.sol";

import {ERC4907} from "../src/ERC4907.sol";
import {ERC5006} from "../src/ERC5006.sol";
import {PoplusERC721} from "../src/PoplusERC721.sol";
import {PoplusERC1155} from "../src/PoplusERC1155.sol";

contract NftFactoryTest is Test {
    uint256 public privateKey = uint256(keccak256("owner"));
    address public owner = vm.addr(privateKey);
    address public bob = makeAddr("bob");
    NftFactory public factory;

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.label(owner, "Owner");

        vm.startPrank(owner);
        factory = new NftFactory();
    }

    function test_Deploy721() public {
        NftFactory.NftInfo memory info = NftFactory.NftInfo({
            name: "test-nft-721",
            symbol: "tn7",
            uri: "",
            recordLimit: 0,
            nftType: 1
        });

        address computeAddress = factory.computeAddress(info, 1);

        address contractAddress = factory.deployNft(info, 1);

        assertEq(computeAddress, contractAddress);

        PoplusERC721 nft = PoplusERC721(contractAddress);

        nft.mint(owner, 1);

        assertEq(nft.name(), info.name);
        assertEq(nft.symbol(), info.symbol);
        assertEq(nft.ownerOf(1), owner);
        assertEq(nft.balanceOf(owner), 1);
    }

    function test_Deploy1155() public {
        NftFactory.NftInfo memory info = NftFactory.NftInfo({
            name: "test-nft-1155",
            symbol: "tn1155",
            uri: "test/",
            recordLimit: 0,
            nftType: 2
        });

        address computeAddress = factory.computeAddress(info, 1);

        address contractAddress = factory.deployNft(info, 1);

        assertEq(computeAddress, contractAddress);

        PoplusERC1155 nft = PoplusERC1155(contractAddress);

        nft.mint(owner, 1, 10);

        assertEq(nft.name(), info.name);
        assertEq(nft.symbol(), info.symbol);
        assertEq(nft.balanceOf(owner, 1), 10);
    }
    function test_Deploy4907() public {
        NftFactory.NftInfo memory info = NftFactory.NftInfo({
            name: "test-nft-4907",
            symbol: "tn4",
            uri: "",
            recordLimit: 0,
            nftType: 3
        });

        address computeAddress = factory.computeAddress(info, 1);

        address contractAddress = factory.deployNft(info, 1);

        assertEq(computeAddress, contractAddress);

        ERC4907 nft = ERC4907(contractAddress);

        nft.mint(owner, 1);

        assertEq(nft.name(), info.name);
        assertEq(nft.symbol(), info.symbol);
        assertEq(nft.ownerOf(1), owner);
        assertEq(nft.balanceOf(owner), 1);
    }

    function test_Deploy5006() public {
        NftFactory.NftInfo memory info = NftFactory.NftInfo({
            name: "test",
            symbol: "test",
            uri: "test",
            recordLimit: type(uint256).max,
            nftType: 4
        });

        address computeAddress = factory.computeAddress(info, 1);

        address contractAddress = factory.deployNft(info, 1);

        assertEq(computeAddress, contractAddress);

        ERC5006 nft = ERC5006(contractAddress);

        nft.mint(owner, 1, 10);

        assertEq(nft.name(), info.name);
        assertEq(nft.symbol(), info.symbol);
        assertEq(nft.balanceOf(owner, 1), 10);
    }

    function test_RevertDuplicationDeploy() public {
        NftFactory.NftInfo memory info = NftFactory.NftInfo({
            name: "test-nft-721",
            symbol: "tn7",
            uri: "",
            recordLimit: 0,
            nftType: 1
        });

        factory.deployNft(info, 1);

        vm.expectRevert(bytes("Contract already deployed with this salt"));
        factory.deployNft(info, 1);
    }
}
