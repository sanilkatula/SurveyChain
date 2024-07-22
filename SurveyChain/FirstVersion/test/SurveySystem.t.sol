// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SurveySystem} from "../src/SurveySystem.sol";

contract SurveySystemTest is Test {
    SurveySystem public surveySystem;

    function setUp() public {
        surveySystem = new SurveySystem();
    }

    function testRegisterUser() public {
        // Test scenario: Register a user with a valid username
        address user = address(0x123);
        string memory username = "Alice";

        // Initially, the roles mapping should not explicitly store any value for the user
        // The default value should be zero, which represents "Registered User" in our contract.
        assertEq(surveySystem.roles(user), 0, "Initial role should be 0 (Registered User)");
        assertEq(bytes(surveySystem.usernames(user)).length, 0, "Initial username should be empty");

        // Register the user
        vm.prank(user); // Sets the msg.sender to 'user' for the next call
        surveySystem.registerUser(username);

        // Verify that the user is registered
        assertEq(surveySystem.roles(user), 0, "Role should be 0 (Registered User)");
        assertEq(surveySystem.usernames(user), username, "Username should be Alice");
    }

    function testRegisterUserEmptyUsername() public {
        // Test scenario: Try to register a user with an empty username
        address user = address(0x456);

        // Attempt to register with an empty username
        vm.prank(user);
        vm.expectRevert(bytes("Username cannot be empty"));
        surveySystem.registerUser("");
    }

    function testRegisterUserMultipleTimes() public {
        // Test scenario: Register a user multiple times with different usernames
        address user = address(0x789);
        string memory username1 = "Bob";
        string memory username2 = "Charlie";

        // Register the user the first time
        vm.prank(user);
        surveySystem.registerUser(username1);

        // Verify the first registration
        assertEq(surveySystem.roles(user), 0, "Role should be 0 (Registered User) after first registration");
        assertEq(surveySystem.usernames(user), username1, "Username should be Bob after first registration");

        // Register the user again with a different username
        vm.prank(user);
        surveySystem.registerUser(username2);

        // Verify that the username is updated
        assertEq(surveySystem.roles(user), 0, "Role should remain 0 (Registered User) after second registration");
        assertEq(surveySystem.usernames(user), username2, "Username should be Charlie after second registration");
    }

    function testRegisterUserWithDuplicateUsername() public {
        // Test scenario: Ensure duplicate usernames are not allowed
        address user1 = address(0xAAA);
        address user2 = address(0xBBB);
        string memory username = "DuplicateUser";

        // Register the first user
        vm.prank(user1);
        surveySystem.registerUser(username);

        // Attempt to register the second user with the same username
        vm.prank(user2);
        vm.expectRevert(bytes("Username already taken"));
        surveySystem.registerUser(username);
    }
    
    function testCreateSurveyAsRegisteredUser() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        address user = address(this);
        vm.prank(user);
        surveySystem.registerUser("TestUser");

        // Simulate a registered user creating a survey
        vm.prank(user);
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
        assertEq(survey.isClosed, false);
        assertEq(survey.owner, user);

        // Verify that the votes array is initialized correctly
        assertEq(survey.votes.length, 2);
        assertEq(survey.votes[0], 0);
        assertEq(survey.votes[1], 0);

        // Verify that the voters array is initialized correctly
        assertEq(survey.voters.length, 0);
    }

    function testFailCreateSurveyAsUnregisteredUser() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Attempt to create a survey without registering
        vm.expectRevert("Only registered users can create a survey");
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);
    }

    function testOwnerCannotVoteInOwnSurvey() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user
        address user = address(this);
        vm.prank(user);
        surveySystem.registerUser("TestUser");

        // Simulate a registered user creating a survey
        vm.prank(user);
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to vote in own survey and expect failure
        vm.prank(user);
        vm.expectRevert("Survey owner cannot vote in their own survey");
        surveySystem.vote(0, 0);
    }

    function testSurveyVoting() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 weeks;
        uint256 maxVotes = 3; // Reduced to 3 for easier testing
        uint256 reward = 10 ether;

        // Register the user who will create the survey
        address user = address(this);
        vm.prank(user);
        surveySystem.registerUser("TestUser");

        // Simulate a registered user creating a survey
        vm.prank(user);
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Unregistered users participating in the survey
        address voter1 = address(0x2);
        address voter2 = address(0x3);
        address voter3 = address(0x4);

        // Simulate voting by unregistered users
        vm.prank(voter1);
        surveySystem.vote(0, 0);
        vm.prank(voter2);
        surveySystem.vote(0, 1);
        vm.prank(voter3);
        surveySystem.vote(0, 0);

        // Retrieve and verify survey details after voting
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.votes[0], 2, "Option 1 should have 2 votes");
        assertEq(survey.votes[1], 1, "Option 2 should have 1 vote");

        // Verify that all voters are recorded
        assertEq(survey.voters.length, 3, "There should be 3 voters");
        assertEq(survey.voters[0], voter1, "Voter1 should be recorded correctly");
        assertEq(survey.voters[1], voter2, "Voter2 should be recorded correctly");
        assertEq(survey.voters[2], voter3, "Voter3 should be recorded correctly");

        // Verify that the survey is closed after reaching max votes
        assertEq(survey.isClosed, true, "Survey should be closed after reaching max votes");

        // Attempt to vote again and expect failure
        vm.prank(voter1);
        vm.expectRevert("Survey is closed");
        surveySystem.vote(0, 1);
    }

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
        address user = address(this);
        vm.prank(user);
        surveySystem.registerUser("TestUser");

        // Simulate a registered user creating a survey
        vm.prank(user);
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to close the survey by a non-owner and expect failure
        address nonOwner = address(0x1);
        vm.prank(nonOwner);
        vm.expectRevert("Only the owner can close the survey");
        surveySystem.closeSurvey(0);
    }
    
    function testSurveyExpiration() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 days; // 1 day duration
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user who will create the survey
        address surveyOwner = address(this);
        vm.prank(surveyOwner);
        surveySystem.registerUser("SurveyOwner");

        // Create the survey
        vm.prank(surveyOwner);
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Fast forward time to after the survey expiration
        vm.warp(block.timestamp + 2 days);

        // Check and close the expired survey
        vm.prank(surveyOwner);
        surveySystem.closeSurvey(0);

        // Verify that the survey is closed
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, true, "Survey should be closed after expiration");
    }

    function testOwnerClosesSurveyManually() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 days; // 1 day duration
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user who will create the survey
        address surveyOwner = address(this);
        vm.prank(surveyOwner);
        surveySystem.registerUser("SurveyOwner");

        // Create the survey
        vm.prank(surveyOwner);
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Attempt to close the survey before expiration
        vm.prank(surveyOwner);
        surveySystem.closeSurvey(0);

        // Verify that the survey is closed
        SurveySystem.Survey memory survey = surveySystem.getSurvey(0);
        assertEq(survey.isClosed, true, "Survey should be closed by the owner before expiration");
    }

    function testDistributeRewards() public {
        // Set up survey parameters
        string memory description = "Test Survey";
        string[] memory choices = new string[](2);
        choices[0] = "Option 1";
        choices[1] = "Option 2";
        uint256 duration = 1 days; // 1 day duration
        uint256 maxVotes = 100;
        uint256 reward = 10 ether;

        // Register the user who will create the survey
        address surveyOwner = address(this);
        vm.prank(surveyOwner);
        surveySystem.registerUser("SurveyOwner");

        // Create the survey
        vm.prank(surveyOwner);
        surveySystem.createSurvey{value: reward}(description, choices, duration, maxVotes, reward);

        // Register two voters
        address voter1 = address(0x1);
        address voter2 = address(0x2);
        vm.prank(voter1);
        surveySystem.registerUser("Voter1");
        vm.prank(voter2);
        surveySystem.registerUser("Voter2");

        // Voters vote in the survey
        vm.prank(voter1);
        surveySystem.vote(0, 0);
        vm.prank(voter2);
        surveySystem.vote(0, 1);

        // Fast forward time to after the survey expiration
        vm.warp(block.timestamp + 2 days);

        // Check and close the expired survey
        vm.prank(surveyOwner);
        surveySystem.closeSurvey(0);

        // Verify initial balances
        uint256 initialBalance1 = voter1.balance;
        uint256 initialBalance2 = voter2.balance;

        // Distribute rewards
        vm.prank(surveyOwner);
        surveySystem.distributeRewards(0);

        // Verify that each voter received the correct reward
        uint256 expectedRewardPerVoter = reward / 2;
        assertEq(voter1.balance, initialBalance1 + expectedRewardPerVoter, "Voter1 did not receive the correct reward");
        assertEq(voter2.balance, initialBalance2 + expectedRewardPerVoter, "Voter2 did not receive the correct reward");
    }
}
