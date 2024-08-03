// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/**
 * @title A sample Auction Contract
 * @author Obed Okoh
 * @notice This contract is for creating a random auction winner
 * @dev Implements chainlink VRFv2 & OpenZeppelin 
 */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Auction is VRFConsumerBaseV2, Ownable {
    /** Errors */
    error Auction_AddressNotInBiddersArray();
    error Auction_AlreadyStarted();
    error Auction_BidNotEnough();
    error Auction_ParameterNotComplete(uint256 numBidders, uint256 currentBalance);
    error Auction_HasNotEnded();

    /** Function declarations */
    enum AuctionState {
        STARTED, // 0
        ENDED // 1
    }
    
    /** Immutable variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_auctionDuration;
    uint256 private immutable i_minimumBid;
    IERC20 private immutable i_myToken;

    /** Storage state variables */
    AuctionState private s_auctionState = AuctionState.STARTED;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address[] private s_bidders;
    mapping(address => bool) private s_isBidder; // holds bidders that are in the array
    mapping(address => uint256) private s_BiddersBid; // hold the bids of the bidders
    uint256 private s_lastTimeStamp;
    address private recentWinner;

    /** Events */
    event BidderRegistered(address indexed bidder);
    event BidPlaced(address indexed bidder, uint256 bid);
    event AuctionHasEnded(address indexed recentWinner);
    event BidderSelected(address indexed winner);

    constructor(
        uint256 auctionDuration,
        uint256 minimumBid,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address myTokenAddress,
        address initialOwner
    ) VRFConsumerBaseV2(vrfCoordinator) Ownable(initialOwner) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_auctionDuration = auctionDuration;
        i_minimumBid = minimumBid;
        s_lastTimeStamp = block.timestamp;
        i_myToken = IERC20(myTokenAddress);
    }

    function registerBidder() external {
        require(!s_isBidder[msg.sender], "Address is already registered");

        s_bidders.push(msg.sender);
        s_isBidder[msg.sender] = true;
        emit BidderRegistered(msg.sender);
    }

    function placeBid() external payable {
        require(s_auctionState == AuctionState.STARTED, "Auction not started");
        // If msg.sender is not among the array of bidders
        if (!s_isBidder[msg.sender]) {
            revert Auction_AddressNotInBiddersArray();
        }
        if (msg.value < i_minimumBid) {
            revert Auction_BidNotEnough();
        }

        // Store the bid in the mapping
        s_BiddersBid[msg.sender] += msg.value; // Sum the bids, bidder might want to add more bid
        emit BidPlaced(msg.sender, msg.value);
    }

    function checkParametersToEndAuction() internal view returns (bool) {
        bool hasBidders = s_bidders.length > 0;
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp >= i_auctionDuration);
        bool hasBalance = address(this).balance > 0;
        bool checker = (hasBidders && timeHasPassed && hasBalance);
        return checker;
    }
    
    function endAuction() external onlyOwner {
        if (!checkParametersToEndAuction()) {
            revert Auction_ParameterNotComplete(
                s_bidders.length,
                address(this).balance
            );
        }
        requestRandomWords();
        s_auctionState = AuctionState.ENDED;
    }

    function requestRandomWords() internal {
        require(s_auctionState == AuctionState.ENDED, "Auction not ended");
        s_requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    // Pick the winner
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        uint256 indexOfWinner = s_randomWords[0] % s_bidders.length;
        recentWinner = s_bidders[indexOfWinner];
        emit BidderSelected(recentWinner);
        emit AuctionHasEnded(recentWinner);
    }

    function withdrawToWinner() external onlyOwner {
        if (s_auctionState != AuctionState.ENDED) {
            revert Auction_HasNotEnded();
        }

        // Transfer ERC-20 MyToken to recentWinner
        require(recentWinner != address(0), "No winner selected");
        uint256 tokenAmount = 100 * (10 ** 18); // 1000 tokens with 18 decimals
        require(i_myToken.balanceOf(address(this)) >= tokenAmount, "Insufficient token balance in auction contract");

        i_myToken.transfer(recentWinner, tokenAmount);
    }
    
    /** Getters */
    function getBidderBid(address bidder) external view returns (uint256) {
        return s_BiddersBid[bidder];
    }
    
    function getAuctionState() external view returns (AuctionState) {
        return s_auctionState;
    }

    function getBidder(uint256 indexOfPlayer) external view returns (address) {
        return s_bidders[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return recentWinner;
    }

    function getLengthOfBidders() external view returns (uint256) {
        return s_bidders.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
