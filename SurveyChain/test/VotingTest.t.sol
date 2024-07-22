// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SurveySystem} from "../src/SurveySystem.sol";

contract VotingTest is Test {
    SurveySystem public surveySystem;
    address public voter = address(0x1); // Address for a non-owner voter

    function setUp() public {
        surveySystem = new SurveySystem();
        vm.deal(voter, 10 ether); // Fund the non-owner voter with ether
    }

    // Test 1: Vote in a survey with valid parameters
    function testVote() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Vote in the survey as a non-owner
        vm.prank(voter);
        surveySystem.vote(0, 0);

        // Retrieve and verify survey details
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.votes[0], 1);
        assertEq(survey.votes[1], 0);
        assertEq(survey.voters.length, 1);
        assertEq(survey.voters[0], voter);
        assertEq(surveySystem.hasVoted(0, voter), 1);
    }

    // Test 2: Attempt to vote in a non-existent survey
    function testVoteInvalidSurvey() public {
        uint256 invalidSurveyId = 999;
        vm.prank(voter);
        vm.expectRevert(bytes("Survey does not exist"));
        surveySystem.vote(invalidSurveyId, 0);
    }

    // Test 3: Attempt to vote before the survey starts
    function testVoteBeforeStart() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey with a future start time
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Fast forward time to before the survey starts
        vm.warp(block.timestamp - 1);

        // Attempt to vote before the survey starts
        vm.prank(voter);
        vm.expectRevert(bytes("Survey has not started yet"));
        surveySystem.vote(0, 0);
    }

    // Test 4: Attempt to vote after the survey ends
    function testVoteAfterEnd() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 days; // 1 day duration
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Fast forward time to after the survey ends
        vm.warp(block.timestamp + 2 days);

        // Attempt to vote after the survey ends
        vm.prank(voter);
        vm.expectRevert(bytes("Survey has ended"));
        surveySystem.vote(0, 0);
    }

    // Test 5: Attempt to vote with an invalid choice
    function testVoteInvalidChoice() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to vote with an invalid choice
        vm.prank(voter);
        vm.expectRevert(bytes("Invalid choice"));
        surveySystem.vote(0, 999); // Invalid choice
    }

    // Test 6: Attempt to vote twice
    function testVoteTwice() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Vote in the survey
        vm.prank(voter);
        surveySystem.vote(0, 0);

        // Attempt to vote again
        vm.prank(voter);
        vm.expectRevert(bytes("You have already voted"));
        surveySystem.vote(0, 1);
    }

    // Test 7: Owner attempts to vote in their own survey
    function testOwnerCannotVote() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");
        
        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to vote as the owner
        vm.expectRevert(bytes("Survey owner cannot vote in their own survey"));
        surveySystem.vote(0, 0);
    }

    // Test 8: Survey automatically closes after reaching max votes
    function testCloseSurveyAfterMaxVotes() public {
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 1; // Set max votes to 1 for testing
        uint256 reward = 10 ether;

        // Ensure the creator (address(this)) is registered
        surveySystem.registerUser("Creator");

        // Create the survey
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Vote in the survey
        vm.prank(voter);
        surveySystem.vote(0, 0);

        // Retrieve and verify survey details
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, 2, "Survey should be closed after reaching max votes");
    }
}