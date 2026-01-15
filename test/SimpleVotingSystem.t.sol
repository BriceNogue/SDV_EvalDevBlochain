// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimplevotingSystem.sol";

contract SimpleVotingSystemTest is Test {
  SimpleVotingSystem public votingSystem;
  address public constant OWNER = address(0x1234567890123456789012345678901234567890);
  address public founder;
  address public voter1;
  address public voter2;
  address public voter3;
  address public candidateWallet;

  event CandidateAdded(uint indexed candidateId, string name);
  event VoteCast(address indexed voter, uint indexed candidateId);

  function setUp() public {
    founder = makeAddr("founder");
    candidateWallet = makeAddr("candidateWallet");
    voter1 = makeAddr("voter1");
    voter2 = makeAddr("voter2");
    voter3 = makeAddr("voter3");

    // Créditer tous les comptes avec de l'ETH pour payer le gas des transactions
    vm.deal(founder, 100 ether); // On donne de l'argent au founder

    vm.deal(OWNER, 100 ether);
    vm.deal(voter1, 10 ether);
    vm.deal(voter2, 10 ether);
    vm.deal(voter3, 10 ether);

    vm.startPrank(OWNER);
    votingSystem = new SimpleVotingSystem(); //msg.sender de la TX est = à l'adress du SC "SimpleVotingSystemTest"

    // On assigne le role founder
    votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
    vm.stopPrank();
  }

  function test_WorkflowAndVote() public {
    vm.prank(OWNER);
    votingSystem.addCandidate("Alice", payable(candidateWallet));

    vm.prank(OWNER);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

    vm.prank(founder);
    votingSystem.fundCandidate{value: 1 ether}(1);
    assertEq(candidateWallet.balance, 1 ether);

    vm.prank(OWNER);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

    vm.prank(voter1);
    vm.expectRevert("Le vote sera ouvert dans 1 heure.");
    votingSystem.vote(1);

    vm.warp(block.timestamp + 3601);

    vm.prank(voter1);
    votingSystem.vote(1);
    
    assertEq(votingSystem.getTotalVotes(1), 1);
    assertEq(votingSystem.balanceOf(voter1), 1);
  }
}
