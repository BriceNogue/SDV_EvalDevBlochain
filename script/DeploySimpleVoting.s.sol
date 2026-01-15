// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {VoteNFT} from "../src/VoteNFT.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract DeploySimpleVoting is Script {
    function run() external returns (SimpleVotingSystem) {
        //start and stop braodcast indicates that everything inside means that we are going to call a RPC Node
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        VoteNFT voteNft = new VoteNFT(msg.sender);
        SimpleVotingSystem simpleVotingSystem = new SimpleVotingSystem();

        vm.stopBroadcast();

        return simpleVotingSystem;
    }
}
