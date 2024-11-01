// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ERC5006} from "../src/ERC5006.sol";
import {IERC5006} from "../interfaces/IERC5006.sol";

contract ERC5006Test is Test {
    uint256 public privateKey = uint256(keccak256("owner"));
    address public owner = vm.addr(privateKey);
    address public bob = makeAddr("bob");
    ERC5006 public nft;

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.label(owner, "Deployer");

        vm.startPrank(owner);

        nft = new ERC5006("test", "test", "test-url/", type(uint256).max);
        vm.label(address(nft), "MultiRentalNFT");
    }

    function test_MintToFrozen() public {
        nft.mint(owner, 1, 10);

        uint256 amount = nft.balanceOf(owner, 1);

        assertEq(10, amount);

        nft.createUserRecord(owner, bob, 1, 3, 600);

        vm.expectEmit(true, true, true, true);

        uint256 frozenBalanceOf = nft.frozenBalanceOf(owner, 1);

        nft.userRecordOf(1);

        assertEq(3, frozenBalanceOf);
    }

    function test_RevetMintToFrozen() public {
        nft.mint(owner, 1, 10);

        uint256 amount = nft.balanceOf(owner, 1);

        assertEq(10, amount);

        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        vm.expectRevert(bytes("only owner or approved"));

        nft.createUserRecord(owner, bob, 1, 3, 600);

        vm.stopPrank();
    }

    function test_ApproveByBobToFrozen() public {
        uint64 expiry = uint64(block.timestamp + 600);

        nft.mint(owner, 1, 20);

        uint256 amount = nft.balanceOf(owner, 1);

        assertEq(amount, 20);

        // Approve to Bob
        nft.setApprovalForAll(bob, true);

        // Forzen By Bob
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);

        nft.createUserRecord(owner, bob, 1, 12, expiry);

        uint256 frozenBalance = nft.frozenBalanceOf(owner, 1);

        IERC5006.UserRecord memory userRecord = nft.userRecordOf(1);

        assertEq(userRecord.user, bob);
        assertEq(userRecord.owner, owner);
        assertEq(userRecord.tokenId, 1);
        assertEq(userRecord.expiry, block.timestamp + 600);
        assertEq(userRecord.amount, 12);
        assertEq(frozenBalance, 12);
    }

    function test_timeOver() public {
        uint64 expiry = uint64(block.timestamp + 600);

        nft.mint(owner, 1, 20);

        uint256 amount = nft.balanceOf(owner, 1);

        assertEq(amount, 20);

        nft.createUserRecord(owner, bob, 1, 12, expiry);

        uint256 usableBalance = nft.usableBalanceOf(bob, 1);

        assertEq(usableBalance, 12);

        // Rental Time Over
        vm.warp(expiry + 1);

        uint256 timeOverUsableBalance = nft.usableBalanceOf(bob, 1);

        assertGt(12, timeOverUsableBalance);
    }

    function test_DeleteUserRecord() public {
        uint64 expiry = uint64(block.timestamp + 600);

        nft.mint(owner, 1, 20);

        uint256 amount = nft.balanceOf(owner, 1);

        assertEq(amount, 20);

        nft.createUserRecord(owner, bob, 1, 20, expiry);

        uint256 beforeNftBalance = nft.balanceOf(address(nft), 1);

        assertEq(beforeNftBalance, 20);

        uint256 beforeUsableBalance = nft.usableBalanceOf(bob, 1);

        assertEq(20, beforeUsableBalance);

        // delete bob record
        nft.deleteUserRecord(1);

        uint256 afterUsableBalance = nft.usableBalanceOf(bob, 1);

        IERC5006.UserRecord memory record = nft.userRecordOf(1);

        uint256 afterNftBalance = nft.balanceOf(address(nft), 1);

        assertEq(afterNftBalance, 0);

        assertEq(0, afterUsableBalance);

        assertEq(record.owner, address(0));
        assertEq(record.user, address(0));
        assertEq(record.expiry, 0);
        assertEq(record.tokenId, 0);
        assertEq(record.amount, 0);
    }
}
