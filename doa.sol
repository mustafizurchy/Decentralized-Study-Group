// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract StudyGroupDAO {
    struct Proposal {
        uint id;
        string description;
        uint voteCount;
        bool executed;
        address proposer;
        uint creationTime;
    }

    struct Member {
        uint balance;
        uint lastProposalId;
    }

    uint public proposalCount;
    uint public totalSupply;
    uint public votingPeriod = 3 days; // Example voting period
    address public admin;

    mapping(address => Member) public members;
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public votes;

    event ProposalCreated(uint proposalId, string description, address proposer);
    event VoteCasted(uint proposalId, address voter);
    event ProposalExecuted(uint proposalId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].balance > 0, "Only members can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Function to join the DAO, requiring a deposit of 1 Ether (or any amount you choose)
    function join() external payable {
        require(msg.value == 1 ether, "Must send 1 Ether to join");
        require(members[msg.sender].balance == 0, "Already a member");

        totalSupply += 1;
        members[msg.sender].balance = 1;
    }

    // Function to create a proposal
    function createProposal(string calldata description) external onlyMembers {
        require(members[msg.sender].lastProposalId == 0 || proposals[members[msg.sender].lastProposalId].executed, "Previous proposal must be executed before creating a new one");

        proposalCount += 1;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            voteCount: 0,
            executed: false,
            proposer: msg.sender,
            creationTime: block.timestamp
        });

        members[msg.sender].lastProposalId = proposalCount;

        emit ProposalCreated(proposalCount, description, msg.sender);
    }

    // Function to vote on a proposal
    function vote(uint proposalId) external onlyMembers {
        require(proposals[proposalId].id == proposalId, "Proposal does not exist");
        require(!votes[proposalId][msg.sender], "Already voted");
        require(block.timestamp <= proposals[proposalId].creationTime + votingPeriod, "Voting period has ended");

        proposals[proposalId].voteCount += 1;
        votes[proposalId][msg.sender] = true;

        emit VoteCasted(proposalId, msg.sender);
    }

    // Function to execute a proposal if it has enough votes
    function executeProposal(uint proposalId) external onlyMembers {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.creationTime + votingPeriod, "Voting period is not over yet");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > totalSupply / 2, "Not enough votes to execute");

        proposal.executed = true;

        // Execute the proposal logic
        // You can implement specific logic here based on the proposal type, e.g., allocate resources, change topic focus, etc.

        emit ProposalExecuted(proposalId);
    }

    // Function to withdraw the Ether deposit (admin-only for simplicity)
    function withdraw() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }
}
