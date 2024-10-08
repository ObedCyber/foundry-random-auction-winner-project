// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    
    function createSubscriptionUsingConfig() public returns(uint64) {       
        HelperConfig helperConfig = new HelperConfig();
        // We only need the vrfcoordinator to create the subscription
        (
                ,
                ,
                address vrfCoordinator,
                ,
                ,
                ,
        ) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64) { 
        console.log("Creating subsciption on chainId: ", block.chainid);
        vm.startBroadcast();
        // triggering the createSubscription button from the Mock file
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub Id is:", subId);
        console.log("Please update subscriptionId in Helperconfig.s.sol");
        return (subId);
    }

    function run() external returns(uint64) {
        return createSubscriptionUsingConfig();
    }

}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        // to fund the subscription we'll need subId, vrf coordinator and link
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link);
    }
    function fundSubscription(address vrfCoordinator, uint64 subId, address link) public {
        console.log("Funding subscription:", subId);
        console.log("Using VRFCoordinator:", vrfCoordinator);
        console.log("On ChainID:", block.chainid);
        // If were on a localchain, the funding method is different from a testnet
        if(block.chainid == 31337){
            vm.startBroadcast();
                VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
        
    }

    function run() external {  
        fundSubscriptionUsingConfig();
    }

}

contract AddConsumer is Script {
    function addConsumer( address auction, address vrfCoordinator, uint64 subId) public
    {
        console.log("Adding consumer Contract: ", auction);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, auction);
        vm.stopBroadcast();

    }

    function addConsumerUsingconfig(address auction) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            
        ) = helperConfig.activeNetworkConfig();
        addConsumer(auction, vrfCoordinator, subId);
    }

    // we will need the most recently deployed auction contract
    function run() external{
        address auction = DevOpsTools.get_most_recent_deployment("Auction", block.chainid);
        addConsumerUsingconfig(auction);
    }
}