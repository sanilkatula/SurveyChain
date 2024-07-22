// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SurveySystem} from "../src/SurveySystem.sol";

contract RewardDistributionTest is Test {
    SurveySystem public surveySystem;
    address public voter1 = address(0x1); // Address for voter 1
    address public voter2 = address(0x2); // Address for voter 2
    address public voter3 = address(0x3); // Address for voter 3

    function setUp() public {
        surveySystem = new SurveySystem();
        vm.deal(voter1, 1 ether); // Fund the voters with ether
        vm.deal(voter2, 1 ether);
        vm.deal(voter3, 1 ether);
        vm.deal(address(this), 10 ether); // Fund the contract itself with some ether
    }

    // Test 1: Distribute rewards to participants
    function testDistributeRewards() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 3;
        uint256 reward = 9 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Vote in the survey
        vm.prank(voter1);
        surveySystem.vote(0, 0);

        vm.prank(voter2);
        surveySystem.vote(0, 1);

        vm.prank(voter3);
        surveySystem.vote(0, 1);

        // Ensure the survey is closed before distributing rewards
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, 2, "Survey should be closed after reaching max votes");

        // Distribute the rewards
        surveySystem.distributeRewards(0);

        // Check the balances of voters
        uint256 expectedReward = 3 ether; // 9 ether divided among 3 voters
        assertEq(voter1.balance, 1 ether + expectedReward, "Voter 1 should receive the reward");
        assertEq(voter2.balance, 1 ether + expectedReward, "Voter 2 should receive the reward");
        assertEq(voter3.balance, 1 ether + expectedReward, "Voter 3 should receive the reward");

        // Verify that the reward has been cleared
        survey = surveySystem.getSurvey(0); // Update the survey variable
        assertEq(survey.reward, 0, "Survey reward should be cleared");
    }

    // Test 2: Distribute rewards with a remainder that returns back to the owner
    function testDistributeRewardsWithRemainder() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 2;
        uint256 reward = 5 ether; // Reward that will leave a remainder when divided by 2

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Vote in the survey
        vm.prank(voter1);
        surveySystem.vote(0, 0);

        vm.prank(voter2);
        surveySystem.vote(0, 1);

        // Ensure the survey is closed automatically after reaching max votes
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, 2, "Survey should be closed after reaching max votes");

        // Capture initial owner balance
        uint256 initialOwnerBalance = address(this).balance;

        // Distribute the rewards
        surveySystem.distributeRewards(0);

        // Check the balances of voters
        uint256 expectedReward = 2.5 ether; // 5 ether divided among 2 voters, 2.5 ether each
        assertEq(voter1.balance, 1 ether + expectedReward, "Voter 1 should receive the reward");
        assertEq(voter2.balance, 1 ether + expectedReward, "Voter 2 should receive the reward");

        // Check the balance of the survey owner for the remainder
        uint256 remainder = reward % 2; // 1 ether remainder
        uint256 expectedOwnerBalance = initialOwnerBalance + remainder;
        assertEq(address(this).balance, expectedOwnerBalance, "Survey owner should receive the remainder");

        // Verify that the reward has been cleared
        survey = surveySystem.getSurvey(0); // Update the survey variable
        assertEq(survey.reward, 0, "Survey reward should be cleared");
    }

    // Test 3: Attempt to distribute rewards for a survey that is not closed
    function testDistributeRewardsNotClosed() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 2;
        uint256 reward = 5 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to distribute rewards before closing the survey
        vm.expectRevert(bytes("Survey is not closed yet"));
        surveySystem.distributeRewards(0);
    }

    // Test 4: Attempt to distribute rewards for a survey with no reward, survey isn't created
    function testDistributeRewardsNoReward() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 2;
        uint256 reward = 0 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        vm.expectRevert(bytes("Reward must be greater than zero"));
        surveySystem.createSurvey(description, choices, duration, maxVotes, reward);
    }
}