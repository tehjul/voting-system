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
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    // ----------
    // modifiers
    // ----------

    modifier onlyRegistered() {
        require(
            voters[msg.sender].isRegistered,
            "Only registered address can propose !"
        );
        _;
    }

    modifier onlyTallied() {
        require(
            _workflowStatusEquals(WorkflowStatus.VotesTallied),
            "Votes aren't tallied !"
        );
        _;
    }

    modifier onlyWorkflowStatus(
        WorkflowStatus _workflowStatus,
        string memory _errorMessage
    ) {
        require(_workflowStatusEquals(_workflowStatus), _errorMessage);
        _;
    }

    // --------
    // getters
    // --------

    function getWinnerProposal()
        public
        view
        onlyTallied
        returns (Proposal memory)
    {
        return proposals[winningProposalId];
    }

    function getWinnerId() public view onlyTallied returns (uint256) {
        return winningProposalId;
    }

    function getWinnerDescription()
        public
        view
        onlyTallied
        returns (string memory)
    {
        return proposals[winningProposalId].description;
    }

    function getWinnerVoteCount() public view onlyTallied returns (uint256) {
        return proposals[winningProposalId].voteCount;
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    function getCurrentWorkflowStatus() public view returns (WorkflowStatus) {
        return workflowStatus;
    }

    function getAddressVote(address _address)
        public
        view
        onlyRegistered
        returns (uint256)
    {
        return voters[_address].votedProposalId;
    }

    // ----------
    // functions
    // ----------

    function whitelist(address _address)
        external
        onlyOwner
        onlyWorkflowStatus(
            WorkflowStatus.RegisteringVoters,
            "Registrations are not open !"
        )
    {
        require(
            !voters[_address].isRegistered,
            "This address is already registered !"
        );
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function changeWorkflowStatus(WorkflowStatus _newWorkflowStatus)
        public
        onlyOwner
    {
        require(
            workflowStatus != _newWorkflowStatus,
            "This workflow status is already set !"
        );
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _newWorkflowStatus;
        emit WorkflowStatusChange(previousStatus, _newWorkflowStatus);
    }

    function propose(string calldata _description)
        public
        onlyRegistered
        onlyWorkflowStatus(
            WorkflowStatus.ProposalsRegistrationStarted,
            "Proposals are not open !"
        )
    {
        require(
            !_proposalAlreadyExists(_description),
            "It has already been proposed !"
        );
        Proposal memory newProposal;
        newProposal.description = _description;
        proposals.push(newProposal);
        emit ProposalRegistered(proposals.length - 1);
    }

    function vote(uint256 _proposalId)
        public
        onlyRegistered
        onlyWorkflowStatus(
            WorkflowStatus.VotingSessionStarted,
            "Votes are not open !"
        )
    {
        require(!voters[msg.sender].hasVoted, "You already voted !");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }

    function setWinner()
        external
        onlyOwner
        onlyWorkflowStatus(
            WorkflowStatus.VotingSessionEnded,
            "Votes are not closed !"
        )
    {
        uint256 _winnerId;
        uint256 _winnerVoteCount;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > _winnerVoteCount) {
                _winnerVoteCount = proposals[i].voteCount;
                _winnerId = i;
            }
        }
        winningProposalId = _winnerId;
        changeWorkflowStatus(WorkflowStatus.VotesTallied);
    }

    // --------
    // helpers
    // --------

    function _proposalAlreadyExists(string calldata _description)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (
                keccak256(abi.encodePacked(proposals[i].description)) ==
                keccak256(abi.encodePacked(_description))
            ) {
                return true;
            }
        }
        return false;
    }

    function _workflowStatusEquals(WorkflowStatus _workflowStatus)
        private
        view
        returns (bool)
    {
        return workflowStatus == _workflowStatus;
    }
}
