// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SkillChallengeIncentives {
    struct Challenge {
        string title;
        string description;
        uint256 rewardPool;
        uint256 deadline;
        address creator;
        address winner;
        bool isActive;
    }

    struct Submission {
        address participant;
        string skillDemo;
        uint256 score;
    }

    mapping(uint256 => Challenge) public challenges; // Tracks challenges by ID
    mapping(uint256 => Submission[]) public submissions; // Tracks submissions for each challenge
    uint256 public challengeCount; // Total number of challenges

    event ChallengeCreated(uint256 indexed challengeId, string title, uint256 rewardPool, uint256 deadline);
    event SubmissionAdded(uint256 indexed challengeId, address participant, string skillDemo);
    event WinnerDeclared(uint256 indexed challengeId, address winner, uint256 reward);

    modifier onlyCreator(uint256 _challengeId) {
        require(challenges[_challengeId].creator == msg.sender, "Only the creator can perform this action.");
        _;
    }

    modifier challengeActive(uint256 _challengeId) {
        require(challenges[_challengeId].isActive, "Challenge is not active.");
        _;
    }

    // Function to create a new challenge
    function createChallenge(
        string memory _title,
        string memory _description,
        uint256 _rewardPool,
        uint256 _duration
    ) external payable {
        require(msg.value == _rewardPool, "Reward pool must be funded with the exact amount.");
        require(_duration > 0, "Duration must be greater than zero.");

        challenges[challengeCount] = Challenge({
            title: _title,
            description: _description,
            rewardPool: _rewardPool,
            deadline: block.timestamp + _duration,
            creator: msg.sender,
            winner: address(0),
            isActive: true
        });

        emit ChallengeCreated(challengeCount, _title, _rewardPool, block.timestamp + _duration);
        challengeCount++;
    }

    // Function for participants to submit their skill demonstration
    function submitSkill(uint256 _challengeId, string memory _skillDemo)
        external
        challengeActive(_challengeId)
    {
        require(block.timestamp <= challenges[_challengeId].deadline, "Challenge deadline has passed.");

        submissions[_challengeId].push(Submission({
            participant: msg.sender,
            skillDemo: _skillDemo,
            score: 0
        }));

        emit SubmissionAdded(_challengeId, msg.sender, _skillDemo);
    }

    // Function to declare the winner of a challenge
    function declareWinner(uint256 _challengeId, uint256 _winnerIndex, uint256 _score)
        external
        onlyCreator(_challengeId)
        challengeActive(_challengeId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(block.timestamp > challenge.deadline, "Challenge is still ongoing.");
        require(challenge.winner == address(0), "Winner has already been declared.");
        require(_winnerIndex < submissions[_challengeId].length, "Invalid winner index.");

        Submission storage winnerSubmission = submissions[_challengeId][_winnerIndex];
        winnerSubmission.score = _score;

        challenge.winner = winnerSubmission.participant;
        challenge.isActive = false;

        payable(winnerSubmission.participant).transfer(challenge.rewardPool);

        emit WinnerDeclared(_challengeId, winnerSubmission.participant, challenge.rewardPool);
    }

    // Function to get all submissions for a specific challenge
    function getSubmissions(uint256 _challengeId) external view returns (Submission[] memory) {
        return submissions[_challengeId];
    }

    // Fallback and receive functions to handle unexpected Ether transfers
    receive() external payable {}

    fallback() external payable {}
}
