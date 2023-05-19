// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/NemuPass.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract NemuPassTest is Test {
    NemuPass public nemuPass;

    address public immutable deployer = address(69);
    address public immutable alice = address(1);

    function setUp() external {
        vm.prank(deployer);
        nemuPass = new NemuPass(100, "ipfs://uwu/", 1000);
        hoax(alice, 100 ether);
    }

    function testMint() external {
        vm.warp(100);
        vm.prank(alice);
        nemuPass.mint{value: 0.1 ether}(1);
    }

    mapping(string => uint256) public randoTest;
    function testRandomization() external {
        vm.warp(100);
        vm.prank(alice);
        nemuPass.mint{value: 50 ether}(500);
        vm.startPrank(deployer);
        uint256 startBlock = 5000;
        for (uint256 i = 0; i < 50; i++) {
            nemuPass.requestBlock();
            startBlock += 5;
            nemuPass.revealBatch();
            startBlock += 50;
        }
        vm.stopPrank();
        for (uint256 i = 0; i < 500; i++) {
            string memory result = nemuPass.tokenURI(i);
            require(randoTest[result] == 0, "conflicting URI");
            randoTest[result] = i;
        }
    }

    function testCannotMintMoreThanSupply() external {
        vm.warp(100);
        vm.startPrank(alice);
        nemuPass.mint{value: 50 ether}(500);
        vm.expectRevert();
        nemuPass.mint{value: 1 ether}(10);
        vm.stopPrank();
    }
}
