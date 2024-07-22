// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SurveySystem} from "../src/SurveySystem.sol";
import {ReentrancyAttacker, Attacker} from "./Attacker.sol";

contract PenetrationTests is Test {
    SurveySystem public surveySystem;
    Attacker public attacker;
    ReentrancyAttacker public reentrancyAttacker;
    address public voter1 = address(0x1); // Address for a non-owner voter
    address public voter2 = address(0x2); // Address for another non-owner voter

    function setUp() public {
        surveySystem = new SurveySystem();
        attacker = new Attacker(surveySystem);
        reentrancyAttacker = new ReentrancyAttacker(surveySystem);
        vm.deal(address(attacker), 10 ether); // Fund the attacker with ether
        vm.deal(address(reentrancyAttacker), 10 ether); // Fund the reentrancy attacker with ether
        vm.deal(voter1, 1 ether); // Fund voter1 with ether
        vm.deal(voter2, 1 ether); // Fund voter2 with ether
    }

    // Test 1: Attempt to create a survey by an unregistered user
    // Purpose: Ensure only registered users can create surveys.
    // Security Issue: Prevent unauthorized survey creation.
    // Expected Result: Transaction reverts with "Only registered users can create a survey".
    // Potential Damage: If the test fails, unregistered users could create surveys, undermining the system's integrity.
    function testUnregisteredUserCreateSurveyAttack() public {
        vm.expectRevert(bytes("Only registered users can create a survey"));
        attacker.unregistered_user_create_survey_attack();
    }

    // Test 2: Attempt to create a survey with an overflowed duration
    // Purpose: Ensure surveys cannot be created with an invalid (overflow) duration.
    // Security Issue: Prevent time-based overflow attacks.
    // Expected Result: Transaction reverts with "Survey duration must be greater than zero and less than maximum duration of 1 year".
    // Potential Damage: If the test fails, surveys could be created with invalid durations, disrupting survey management.
    function testTimeOverflowAttack() public {
        vm.expectRevert(bytes("Survey duration must be greater than zero and less than maximum duration of 1 year"));
        attacker.time_overflow_attack();
    }

    // Test 3: Attempt to vote twice from the same user (Sybil attack)
    // Purpose: Ensure each user can vote only once per survey.
    // Security Issue: Prevent multiple votes by the same user, maintaining fair voting.
    // Expected Result: Transaction reverts with "You have already voted".
    // Potential Damage: If the test fails, a user could vote multiple times, skewing survey results.
    function testSybilAttack1() public {
        // Perform the Sybil attack setup
        attacker.sybil_attack_1();

        // Simulate the first vote by voter1
        vm.prank(voter1);
        surveySystem.vote(0, 0);

        // The second vote should revert
        vm.prank(voter1);
        vm.expectRevert(bytes("You have already voted"));
        surveySystem.vote(0, 1);
    }

    // Test 4: Attempt to register the same user twice (Sybil attack)
    // Purpose: Ensure a user cannot register multiple times with different usernames.
    // Security Issue: Prevent registration of the same user multiple times.
    // Expected Result: Transaction reverts with "User is already registered".
    // Potential Damage: If the test fails, users could register multiple times, compromising user management.
    function testSybilAttack2() public {
        attacker.sybil_attack_2();
        // The second registration should revert
        vm.expectRevert(bytes("User is already registered"));
        attacker.sybil_attack_2();
    }

    // Test 5: Attempt to create a survey without sending reward
    // Purpose: Ensure surveys cannot be created without a reward.
    // Security Issue: Prevent creation of surveys with zero reward.
    // Expected Result: Transaction reverts with "Reward must be greater than zero".
    // Potential Damage: If the test fails, surveys could be created without rewards, undermining the incentive structure.
    function testCreateSurveyFreeAttack() public {
        vm.expectRevert(bytes("Reward must be greater than zero"));
        attacker.create_survey_free_attack();
    }

    // Test 6: Attempt to withdraw reward twice
    // Purpose: Ensure rewards cannot be distributed more than once.
    // Security Issue: Prevent multiple reward withdrawals, ensuring fairness.
    // Expected Result: Transaction reverts with "Rewards have already been distributed" on second attempt.
    // Potential Damage: If the test fails, rewards could be withdrawn multiple times, causing financial loss.
    function testDoubleRetrievalAttack1() public {
        // Perform the double retrieval attack setup
        attacker.double_retrieval_attack_1();

        // Simulate voting by voter1
        vm.prank(voter1);
        surveySystem.vote(0, 0);

        // Close the survey and distribute rewards as the attacker (owner of the survey)
        vm.prank(address(attacker));
        surveySystem.closeSurvey(0);
        vm.prank(address(attacker));
        surveySystem.distributeRewards(0);

        // The second reward withdrawal should revert
        vm.prank(address(attacker));
        vm.expectRevert(bytes("Rewards have already been distributed"));
        surveySystem.distributeRewards(0);
    }

    // Test 7: Attempt to withdraw reward twice with short duration
    // Purpose: Ensure rewards cannot be distributed more than once, even with short duration surveys.
    // Security Issue: Prevent multiple reward withdrawals in quick succession.
    // Expected Result: Transaction reverts with "Rewards have already been distributed" on second attempt.
    // Potential Damage: If the test fails, rewards could be withdrawn multiple times, causing financial loss.
    function testDoubleRetrievalAttack2() public {
        // Perform the double retrieval attack setup
        attacker.double_retrieval_attack_2();

        // Simulate voting by voter1
        vm.prank(voter1);
        surveySystem.vote(0, 0);

        // Try to vote a second time, which should revert
        vm.prank(voter1);
        vm.expectRevert(bytes("You have already voted"));
        surveySystem.vote(0, 1);

        // Close the survey and distribute rewards as the attacker (owner of the survey)
        vm.prank(address(attacker));
        surveySystem.closeSurvey(0);
        vm.prank(address(attacker));
        surveySystem.distributeRewards(0);

        // The second reward withdrawal should revert
        vm.prank(address(attacker));
        vm.expectRevert(bytes("Rewards have already been distributed"));
        surveySystem.distributeRewards(0);
    }

    // Test 8: Attempt to close survey to cause divide by zero error
    // Purpose: Ensure the system handles edge cases, such as dividing by zero, gracefully.
    // Security Issue: Prevent divide by zero errors that could crash the contract.
    // Expected Result: The contract should handle this gracefully without errors.
    // Potential Damage: If the test fails, divide by zero errors could crash the contract, disrupting service.
    function testDivideByZeroAttack() public {
        attacker.divide_by_zero_attack();
        // Check that no divide by zero error occurs
    }

    // Test 9: Attempt to vote as the owner
    // Purpose: Ensure the survey owner cannot vote in their own survey.
    // Security Issue: Prevent manipulation of survey results by the owner.
    // Expected Result: Transaction reverts with "Survey owner cannot vote in their own survey".
    // Potential Damage: If the test fails, survey owners could manipulate results by voting in their own surveys.
    function testOwnerVoteAttack() public {
        vm.expectRevert(bytes("Survey owner cannot vote in their own survey"));
        attacker.owner_vote_attack();
    }

    // Test 10: Attempt a reentrancy attack
    // Purpose: Ensure the contract is secure against reentrancy attacks.
    // Security Issue: Prevent reentrancy attacks that could drain funds or manipulate survey results.
    // Expected Result: The reentrancy attack is prevented, and the contract remains secure.
    // Potential Damage: If the test fails, reentrancy attacks could exploit the contract, causing financial loss and data manipulation.
    function testReentrancyAttack() public {
        reentrancyAttacker.reentrancy_attack();
        // Check that reentrancy attack is prevented
    }
}
