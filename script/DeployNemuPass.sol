//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NemuPass.sol";

contract DeployNemuPassScript is Script {
    address multisig = 0x8D59Bd566f8159630ffF921E82731d12D3ea60f2;

    function run() external {
        uint256 privateKey = vm.envUint("PRIV_KEY");
        vm.startBroadcast(privateKey);
        NemuPass nemupass = new NemuPass(block.timestamp + 86400);
        nemupass.transferRealOwnership(multisig);
        vm.stopBroadcast();
    }
}
