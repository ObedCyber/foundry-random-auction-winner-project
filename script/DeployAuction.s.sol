// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Auction} from "../src/Auction.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MyToken} from "../src/MyToken.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployAuction is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    /* uint256 auctionDuration = 30;  
    uint256 minimumBid = 0.01 ether; */
    address initialOwner;
    function run() external returns (Auction,HelperConfig, address) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 minimumBid,
            uint256 auctionDuration,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // we are going to need to create a subscription!
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator
            );

            // fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link
            );
        }

        if (block.chainid == 11155111) {
            initialOwner = /* 0xE838b4a4aAa6084e24d526295D9a5ccff9C7ab4d */;
        } else {
            initialOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        }

        vm.startBroadcast();
        // Deploy MyToken contract
        MyToken myToken = new MyToken(INITIAL_SUPPLY);
        // Deploy Auction contract with the address of the deployed MyToken contract
        Auction auction = new Auction(
            auctionDuration,
            minimumBid,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            address(myToken),
            initialOwner
        );
        console.log("MyToken contract deployed at:", address(myToken));
        console.log("Auction contract deployed at:", address(auction));
        console.log("Initial Owner is:", address(initialOwner));
        vm.stopBroadcast();

        // Add Consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(auction),
            vrfCoordinator,
            subscriptionId
        );

        return (auction, helperConfig, initialOwner);
    }
}