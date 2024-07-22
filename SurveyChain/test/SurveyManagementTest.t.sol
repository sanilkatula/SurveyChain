// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SurveySystem} from "../src/SurveySystem.sol";

contract SurveyManagementTest is Test {
    SurveySystem public surveySystem;

    function setUp() public {
        surveySystem = new SurveySystem();
    }

    // Test 1: Create a survey with valid parameters by a registered user
    function testCreateSurvey() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Retrieve and verify survey details
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.description, description);
        assertEq(survey.choices.length, 2);
        assertEq(survey.choices[0], "Option 1");
        assertEq(survey.choices[1], "Option 2");
        assertEq(survey.startTime, block.timestamp);
        assertEq(survey.endTime, block.timestamp + duration);
        assertEq(survey.maxVotes, maxVotes);
        assertEq(survey.reward, reward);
        assertEq(survey.isClosed, 1); // Open
        assertEq(survey.owner, address(this));

        // Verify that the votes array is initialized correctly
        assertEq(survey.votes.length, 2);
        assertEq(survey.votes[0], 0);
        assertEq(survey.votes[1], 0);

        // Verify that the voters array is initialized correctly
        assertEq(survey.voters.length, 0);
    }

    // Test 2: Attempt to create a survey without choices by a registered user
    function testCreateSurveyWithoutChoices() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](0); // No choices
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Expect revert due to lack of choices
        vm.expectRevert(bytes("Survey must have at least one choice"));
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);
    }

    // Test 3: Attempt to create a survey with zero duration by a registered user
    function testCreateSurveyWithZeroDuration() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 0; // Zero duration
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Expect revert due to zero duration
        vm.expectRevert(bytes("Survey duration must be greater than zero and less than maximum duration of 1 year"));
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);
    }

    // Test 4: Attempt to create a survey with zero max votes by a registered user
    function testCreateSurveyWithZeroMaxVotes() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 0; // Zero max votes
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Expect revert due to zero max votes
        vm.expectRevert(bytes("Max votes must be greater than zero"));
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);
    }

    // Test 5: Attempt to create a survey with zero reward by a registered user
    function testCreateSurveyWithZeroReward() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 0; // Zero reward

        // Register the user
        surveySystem.registerUser("TestUser");

        // Expect revert due to zero reward
        vm.expectRevert(bytes("Reward must be greater than zero"));
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);
    }

    // Test 6: Attempt to create a survey with invalid reward (mismatch between msg.value and reward) by a registered user
    function testCreateSurveyWithInvalidReward() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Expect revert due to reward value mismatch
        vm.expectRevert(bytes("Reward value must be sent"));
        surveySystem.createSurvey{value: reward - 1}(description, choices, duration, maxVotes, reward); // Sending less ether than reward
    }

    // Test 7: Close a survey by the owner
    function testCloseSurveyManuallyByOwner() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Close the survey
        surveySystem.closeSurvey(0);

        // Retrieve and verify survey details
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, 2, "Survey should be closed");
    }

    // Test 8: Ensure Non-Owners cannot close a survey
    function testNonOwnerCantCloseSurvey() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Simulate a registered user creating a survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to close the survey by a non-owner and expect failure
        address nonOwner = address(0x1);
        vm.prank(nonOwner);
        vm.expectRevert("Only the owner can close the survey");
        surveySystem.closeSurvey(0);
    }

    // Test 9: Close a survey automatically after expiration
    function testSurveyExpiration() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 days; // 1 day duration
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        surveySystem.registerUser("TestUser");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Fast forward time to after the survey expiration
        vm.warp(block.timestamp + 2 days);

        // Close the expired survey
        surveySystem.closeSurvey(0);

        // Retrieve and verify survey details
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, 2, "Survey should be closed after expiration");
    }

    // Test 10: Attempt to create a survey by an unregistered user
    function testUnregisteredUserCannotCreateSurvey() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Expect revert due to user not being registered
        vm.expectRevert(bytes("Only registered users can create a survey"));
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);
    }
}