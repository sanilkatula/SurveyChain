// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UserManagement {
    mapping(address => uint256) public roles; // 1: Registered User, 0: Unregistered User
    mapping(address => string) public usernames;
    mapping(string => uint256) public usernameTaken; // Track if a username is taken

    // Function to register a user
    function registerUser(string memory username) public {
        require(bytes(username).length > 0, "Username cannot be empty");
        require(roles[msg.sender] == 0, "User is already registered");
        require(usernameTaken[username] == 0, "Username is already taken");

        usernames[msg.sender] = username;
        roles[msg.sender] = 1; // Registered User
        usernameTaken[username] = 1; // Mark the username as taken
    }
}