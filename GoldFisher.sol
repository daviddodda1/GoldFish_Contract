// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract GoldFisher {
    /// @notice Array of whitelisted users that are permitted to mint during Wave 1
    address public admin;

    uint256 public costToReactToBubble = 1000000000000000; // 0.001 ETH

    uint256 public costToSub = 10000000000000000; // 0.01 ETH

    uint256 public lastCubClearTime = 0;

    mapping(address => bool) public whitelist;

    struct BubbleObject {
        uint256 timeStamp;
        string text;
        uint256 reactionCount;
    }

    struct UserProfile {
        string name;
        string bio;
        string profilePic;
        uint256 subCount;
    }

    mapping(address => UserProfile) public userProfiles;

    mapping(address => BubbleObject[]) public userBubbles;

    mapping(address => mapping(address => uint256)) public userSubs;

    constructor(address[] memory _whitelistAddresses) {
        admin = msg.sender;
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelist[_whitelistAddresses[i]] = true;
        }
        lastCubClearTime = block.timestamp;
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == admin, "No permission");
        admin = newAdmin;
    }

    function clearSubs(address[] memory whitelistArr) external {
        require(msg.sender == admin, "No permission");
        for (uint256 i = 0; i < whitelistArr.length; i++) {
            userProfiles[whitelistArr[i]].subCount = 0;
        }
        lastCubClearTime = block.timestamp;
    }

    /// @notice Fetch the array of whitelisted users
    function addToWhiteList(address[] memory additionalWhiteListAddresses)
        external
    {
        require(msg.sender == admin, "No permission");
        for (uint256 i = 0; i < additionalWhiteListAddresses.length; i++) {
            whitelist[additionalWhiteListAddresses[i]] = true;
        }
    }

    function removeWhiteList(address[] memory additionalWhiteListAddresses)
        external
    {
        require(msg.sender == admin, "No permission");
        for (uint256 i = 0; i < additionalWhiteListAddresses.length; i++) {
            whitelist[additionalWhiteListAddresses[i]] = false;
        }
    }

    /// @notice Checks if an address is whitelisted
    /// @param userAddress Address to check
    function whitelistedAddresses(address userAddress)
        public
        view
        returns (bool)
    {
        return whitelist[userAddress];
    }

    // Update User Profile
    function updateProfile(
        string memory name,
        string memory bio,
        string memory profilePic
    ) public {
        require(whitelist[msg.sender], "Not whitelisted");
        userProfiles[msg.sender] = UserProfile(
            name,
            bio,
            profilePic,
            userProfiles[msg.sender].subCount
        );
    }

    // getCreator Profile
    function getProfile(address userAddress)
        public
        view
        returns (UserProfile memory)
    {
        require(whitelist[userAddress], "User Not Creator");
        return userProfiles[userAddress];
    }

    // get user bubbles(tweets)
    function getBubbles(address userAddress)
        public
        view
        returns (BubbleObject[] memory)
    {
        require(whitelist[userAddress], "User Not Creator");
        return userBubbles[userAddress];
    }

    // create a Bubble
    function createBubble(address userAddress, string memory text) external {
        require(whitelist[msg.sender], "Not whitelisted");

        // clear bubbles if more than 30
        if (userBubbles[userAddress].length > 30) {
            delete userBubbles[userAddress];
        }
        userBubbles[userAddress].push(BubbleObject(block.timestamp, text, 0));
    }

    // react to a bubble
    function reactToBubble(address userAddress, uint256 bubbleIndex)
        public
        payable
    {
        require(msg.value >= costToReactToBubble, "NOETH");
        require(userBubbles[userAddress].length > bubbleIndex, "NOBUBBLE");

        // pay the creator
        payable(userAddress).transfer((msg.value * 90) / 100); // 80% to creator 20% to contract

        // increment reaction count
        userBubbles[userAddress][bubbleIndex].reactionCount++;
    }

    // sub to a user
    function subToUser(address userAddress) public payable {
        require(msg.value >= costToSub, "NOETH");
        require(whitelist[userAddress], "NOTWHITELISTED");

        // increment reaction count
        userSubs[userAddress][msg.sender] = block.timestamp;

        // increment sub count
        userProfiles[userAddress].subCount++;

        // pay the creator
        payable(userAddress).transfer((msg.value * 90) / 100); // 90% to creator 10% to contract
    }

    // check if user is subbed to another user
    function checkUserSub(address userAddress)
        public
        view
        returns (string memory)
    {
        string memory resPonse = "{";
        resPonse = string(
            abi.encodePacked(
                "{",
                "'subState':",
                userSubs[userAddress][msg.sender] > lastCubClearTime
                    ? "true"
                    : "false",
                ", 'lastSubTime':",
                Strings.toString(userSubs[userAddress][msg.sender]),
                "}"
            )
        );
        return resPonse;
    }

    function withdraw() external {
        require(msg.sender == admin, "No permission");
        payable(msg.sender).transfer(address(this).balance);
    }
}
