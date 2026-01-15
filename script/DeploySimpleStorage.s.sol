// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimplestorage is Script {
    function run() external returns (SimpleStorage) {
        //start and stop braodcast indicates that everything inside means that we are going to call a RPC Node
        vm.startBroadcast();
        SimpleStorage simpleStorage = new SimpleStorage();
        vm.stopBroadcast();
        return simpleStorage;
    }
}
