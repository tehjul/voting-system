// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    uint256 winningProposalId;
    uint256 currentProposalId;
    WorkflowStatus workflowStatus;
    Proposal[] public proposals;

    mapping(address => Voter) voters;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    // modifiers

    modifier onlyRegistered() {
        require(voters[msg.sender].isRegistered, "Only registered address can propose !");
        _;
    }

    // getters

    function getWinner() public view returns (Proposal memory) {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Votes aren't finished !");
        return proposals[winningProposalId];
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    // functions

    function whitelist(address _address) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Registrations are not open !");
        require(!voters[_address].isRegistered, "This address is already registered !");
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function changeWorkflowStatus(WorkflowStatus _newWorkflowStatus) external onlyOwner {
        require(workflowStatus != _newWorkflowStatus, "This workflow status is already set !");
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _newWorkflowStatus;
        emit WorkflowStatusChange(previousStatus, _newWorkflowStatus);
    }

    function propose(string calldata _description) public onlyRegistered {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals are not open !");
        require(!proposalAlreadyExists(_description), "It has already been proposed !");
        Proposal memory newProposal;
        newProposal.description = _description;
        proposals.push(newProposal);
        emit ProposalRegistered(proposals.length - 1);
    }

    function vote(uint256 _proposalId) public onlyRegistered {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Votes are not open !");
        require(!voters[msg.sender].hasVoted, "You already voted !");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount += 1;
        emit Voted(msg.sender, _proposalId);
    }

    // Helpers

    function proposalAlreadyExists(string calldata _description) internal view returns (bool) {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (keccak256(abi.encodePacked(proposals[i].description)) == keccak256(abi.encodePacked(_description))) {
                return true;
            }
        }
        return false;
    }
}
