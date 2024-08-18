// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Auction} from "../../src/Auction.sol";
import {DeployAuction} from "../../script/DeployAuction.s.sol";
import {MyToken} from "../../src/MyToken.sol";

contract AuctionTest is Test {

    /**Events */
    event BidderRegistered(address indexed bidder);

    Auction auction;
    HelperConfig helperConfig;
    MyToken myToken;
    address initialOwner;

    uint256 minimumBid;
    uint256 auctionDuration;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public USER_1 = makeAddr("user_1");
    address public USER_2 = makeAddr("user_2");
    uint256 public constant STARTING_USER_BALANCE = 3 ether;

    function setUp() external {
        DeployAuction deployAuction = new DeployAuction();
        (auction, helperConfig,) = deployAuction.run();

        (
             minimumBid,
             auctionDuration,            
             vrfCoordinator,
             gasLane,
             subscriptionId,
             callbackGasLimit,
             link
            ) = helperConfig.activeNetworkConfig();

            // retireve the address of the deploy MyToken contract
            address myTokenAddress = auction.getmyTokenAddress();
    }

    function testInitialOwnerIsSetCorrectly() public {
         DeployAuction deployAuction = new DeployAuction();
        (auction, helperConfig, initialOwner) = deployAuction.run();
        //console.log(auction.getOwner());
        assertEq(auction.getOwner(), initialOwner, "Owner is not set correctly.");
    } 

    function testRegisterBidder() public {
        vm.prank(USER_1);
        auction.registerBidder();
        address registeredBidder = auction.getBidder(0);
        assertEq(registeredBidder, USER_1, "Bidder was not registered correctly.");
    }

    function testRegisterBidderEmitsEvent() public {
        vm.prank(USER_1);
        vm.expectEmit(true, true, true, true);
        emit BidderRegistered(USER_1);
        auction.registerBidder();
    }

    function testBidderRegisteredTwice() public {
        vm.prank(USER_1);
        auction.registerBidder();
        // expect revert
        vm.expectRevert(bytes("Address is already registered"));        //Register the bidder again
        vm.prank(USER_1);
        auction.registerBidder();
    }

    function testUserNotAmongBidders() public {    
        vm.prank(USER_2);
        // vm.expectRevert(Auction.Auction_AddressNotInBiddersArray.selector);
        vm.expectRevert();
        auction.placeBid{value: STARTING_USER_BALANCE}();
    }

    function testUserCannotPlaceBidWhenAuctionHasEnded() public {
        vm.prank(auction.getOwner());
        auction.setAuctionStateToEnded();
        vm.expectRevert(bytes("Auction not started"));
        auction.placeBid();
    }

    function testBidPlacedIsNotEnough() public {
        uint256 Bid_Amount = 0.1 ether;
        vm.prank(USER_1);
        auction.registerBidder();
        vm.prank(USER_1);
        vm.deal(USER_1, Bid_Amount);
        vm.expectRevert(Auction.Auction_BidNotEnough.selector);
        auction.placeBid{value: Bid_Amount}();
    }

    function testBidPlacedOnceAndStoredInMapping() public {
        vm.prank(USER_1);
        auction.registerBidder();
        vm.prank(USER_1);
        vm.deal(USER_1, STARTING_USER_BALANCE);
        auction.placeBid{value: STARTING_USER_BALANCE}();
        assertEq(STARTING_USER_BALANCE, auction.getBidderBid(USER_1));
    }

    function testBidPlacedTwiceAndStoredInMapping() public {
        // Register the bidder
        vm.prank(USER_1);
        auction.registerBidder();

        // Set initial balance for USER_1
        uint256 balance = STARTING_USER_BALANCE;
        vm.deal(USER_1, balance);

        // Place two bids
        vm.prank(USER_1);
        auction.placeBid{value: minimumBid}();
        vm.prank(USER_1);
        auction.placeBid{value: minimumBid}();
        
        // Assert that the total bid amount is stored correctly
        assertEq(2 * minimumBid, auction.getBidderBid(USER_1));
    }

    function testCannotEndAuctionWithNoBidders() public {
    assertEq(auction.getLengthOfBidders(), 0);
    vm.warp(block.timestamp + auctionDuration);
    vm.prank(auction.getOwner());
    vm.expectRevert(abi.encodeWithSelector(
            Auction.Auction_ParameterNotComplete.selector,
            0, 
            0  
        ));    
    auction.endAuction();
    }

    function testCannotEndAuctionBeforeTime() public {
    // Register a bidder and place a bid
    vm.prank(USER_1);
    auction.registerBidder();
    vm.deal(USER_1, STARTING_USER_BALANCE);
    vm.prank(USER_1);
    auction.placeBid{value: minimumBid}();

    uint256 lengthOfBidders = auction.getLengthOfBidders();

    // Ensure the auction has not yet reached its end time
    // assert less than
    assertLt(block.timestamp, auction.getLastTimeStamp() + auctionDuration);
    vm.prank(auction.getOwner());
    // Expect the auction to revert since time has not passed
    vm.expectRevert(abi.encodeWithSelector(
                Auction.Auction_ParameterNotComplete.selector,
                lengthOfBidders,
                minimumBid  
            ));    
    auction.endAuction();
    }



    
    
}