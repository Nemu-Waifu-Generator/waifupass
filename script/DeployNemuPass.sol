//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NemuPass.sol";

contract DeployNemuPassScript is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIV_KEY");
        vm.startBroadcast(privateKey);
        NemuPass nemupass = new NemuPass(
            "ipfs://bafybeierhfoa46rq5b33sya66d2eelhfbyf4hbtqh75kjgki2isrcks7fi/",
            "ipfs://",
            true,
            5,
            block.timestamp + 86400
        );
        vm.stopBroadcast();
    }
}
