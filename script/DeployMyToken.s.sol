// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {console} from "forge-std/console.sol";

contract DeployOurToken is MyToken {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns (MyToken) {
        vm.startBroadcast();
        MyToken myToken = new MyToken(INITIAL_SUPPLY);
        console.log("MyToken deployed to:", address(myToken));
        vm.stopBroadcast();
        return myToken;
    }
}