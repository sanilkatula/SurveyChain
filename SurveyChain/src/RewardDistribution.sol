// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Voting.sol";

contract RewardDistribution is SurveyManagement {
    // For reward distribution to participants
    function distributeRewards(uint256 _surveyId) public {
        require(_surveyId < surveys.length, "Survey does not exist");
        Survey storage survey = surveys[_surveyId];
        require(survey.isClosed == 2, "Survey is not closed yet");
        require(survey.rewardsDistributed == 0, "Rewards have already been distributed");
        require(survey.reward > 0, "No rewards available");
        require(survey.voters.length > 0, "No voters to distribute rewards to");

        uint256 totalVoters = survey.voters.length;
        uint256 rewardPerVoter = survey.reward / totalVoters;
        uint256 remainder = survey.reward % totalVoters;

        for (uint256 i = 0; i < totalVoters; i++) {
            address voter = survey.voters[i];
            // Using call to transfer Ether and limiting gas
            (bool success, ) = voter.call{value: rewardPerVoter}("");
            require(success, "Transfer failed");
        }

        // Handle the remainder
        if (remainder > 0) {
            // Send the remainder to the survey owner or leave it in the contract
            (bool success, ) = survey.owner.call{value: remainder}("");
            require(success, "Remainder transfer failed");
        }

        // Set the rewardsDistributed flag to 1 (yes) and clear the reward to prevent re-entrancy
        survey.rewardsDistributed = 1; // Yes
        survey.reward = 0;
    }
}
