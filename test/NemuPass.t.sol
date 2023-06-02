// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NemuPass.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract NemuPassTest is Test {
    NemuPass public nemuPass;

    address public immutable deployer = address(69);
    address public immutable alice = address(1);
    address public immutable bob = address(2);

    function setUp() external {
        vm.prank(deployer);
        nemuPass = new NemuPass(50);
    }

    function testMint() external {
        vm.warp(100);
        vm.prank(alice);
        nemuPass.mint{value: 0.1 ether}(1);
    }

    function testRandomization() external {
        vm.warp(100);
        vm.prank(alice);
        nemuPass.mint{value: 0.5 ether}(5);
        vm.warp(150);
        vm.prank(bob);
        nemuPass.mint{value: 0.5 ether}(5);
        vm.startPrank(deployer);
        vm.warp(1000);
        nemuPass.revealBatch();
        vm.warp(1500);
        nemuPass.revealBatch();
        vm.stopPrank();
        for (uint256 i = 0; i < 10; i++) {
            string memory result = nemuPass.tokenURI(i);
            console.log(result);
        }
    }

}
