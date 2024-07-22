// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./UserManagement.sol";
import "./Voting.sol";
import "./RewardDistribution.sol";
import "./SurveyManagement.sol";

contract SurveySystem is 
    UserManagement, SurveyManagement, 
    Voting, RewardDistribution {}