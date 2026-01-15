// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract SimpleVotingSystem  is Ownable, AccessControl, ERC721{

    // Rôles 
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // Etats
    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        address payable wallet; // Pour le financement
    }

    // Variables d'état
    WorkflowStatus public workflowStatus;
    uint public voteStartTime;
    uint private _nextTokenId;

    mapping(uint => Candidate) public candidates;
    //mapping(address => bool) public voters;
    uint[] private candidateIds;

    // Evénements
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event CandidateAdded(uint indexed id, string name);
    event Voted(address indexed voter, uint candidateId);
    event FundsSent(address indexed to, uint amount);

    constructor() Ownable(msg.sender) ERC721("VoteNFT", "VNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        workflowStatus = WorkflowStatus.REGISTER_CANDIDATES;
    }

    // Gestion Workflow par l'Admin
    function setWorkflowStatus(WorkflowStatus _newStatus) external onlyOwner {
        require(uint(_newStatus) > uint(workflowStatus), "Retour en arriere impossible.");
        
        // Si on passe au vote, on lance le chronometre pour un delai d'1h
        if (_newStatus == WorkflowStatus.VOTE) {
            voteStartTime = block.timestamp;
        }

        emit WorkflowStatusChange(workflowStatus, _newStatus);
        workflowStatus = _newStatus;
    }

    function addCandidate(string memory _name, address payable _wallet) public onlyOwner {
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Statut invalide pour l'ajout.");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(_wallet != address(0), "Adresse invalide.");

        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);

        emit CandidateAdded(candidateId, _name);
    }

    // Financement des candidats
    function fundCandidate(uint _candidateId) external payable onlyRole(FOUNDER_ROLE) {
        require(workflowStatus == WorkflowStatus.FOUND_CANDIDATES, "Statut invalide pour le financement.");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "ID Candidat invalide");
        require(msg.value > 0, "Montant nul interdit");

        Candidate memory recipient = candidates[_candidateId];
        
        (bool sent, ) = recipient.wallet.call{value: msg.value}("");
        require(sent, "Echec envoi ETH");

        emit FundsSent(recipient.wallet, msg.value);
    }

    function vote(uint _candidateId) public {
        require(workflowStatus == WorkflowStatus.VOTE, "Le vote est clos ou pas encore ouvert.");
        require(block.timestamp >= voteStartTime + 1 hours, "Le vote sera ouvert dans 1 heure.");
        //require(!voters[msg.sender], "You have already voted");
        require(balanceOf(msg.sender) == 0, "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        // Mint du NFT de vote
        _nextTokenId++;
        _safeMint(msg.sender, _nextTokenId);

        //voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;

        emit Voted(msg.sender, _candidateId);
    }

    // Resultats du vote
    function getWinner() public view returns (string memory name, uint count) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Le vote n'est pas terminé.");
        
        uint winningVoteCount = 0;
        uint winningId = 0;

        for (uint i = 0; i < candidateIds.length; i++) {
            if (candidates[candidateIds[i]].voteCount > winningVoteCount) {
                winningVoteCount = candidates[candidateIds[i]].voteCount;
                winningId = candidates[candidateIds[i]].id;
            }
        }
        
        if (winningId != 0) {
            return (candidates[winningId].name, winningVoteCount);
        }
    }

    // Retrait des fonds
    function withdraw() external onlyRole(WITHDRAWER_ROLE) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Le vote n'est pas terminé.");
        
        uint balance = address(this).balance;
        require(balance > 0, "Aucun fonds à retirer.");

        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Echec du retrait.");
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    // Optional: Function to get candidate details by ID
    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }

    // Override obligatoire pour solidity pour eviter le conflit AccessControl/ERC721
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}