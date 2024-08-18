# Random Auction Project

## Overview

The Random Auction Project is a decentralized auction system built using Solidity on the Foundry framework. The auction contract leverages Chainlink VRF (Verifiable Random Function) to determine a random winner among the participants, ensuring fairness and transparency. The auction transfers an ERC20 token ("MyToken") to the winner at the end of the auction.

## Features

- **Random Winner Selection:** Utilizes Chainlink VRF to ensure randomness in selecting the auction winner.
- **Customizable Auction Parameters:** The auction contract supports configurable parameters such as auction duration, minimum bid, and callback gas limit.
- **Secure Bidding:** Participants can place bids securely, with their bids being tracked and managed on-chain.
- **Token Transfer:** The auction contract is designed to transfer the specified ERC20 token to the winner automatically.
- **Testing:** Comprehensive testing using Foundry to ensure the correct functionality of the bidding process and balance management.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- [Foundry](https://book.getfoundry.sh/) installed
- [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/) installed
- [Chainlink VRF subscription](https://docs.chain.link/docs/get-a-random-number/) set up

## Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/ObedCyber/foundry-random-auction-winner-project.git
    cd foundry-random-auction-winner-project
    ```

2. **Install Foundry:**

    Follow the official Foundry installation guide [here](https://book.getfoundry.sh/getting-started/installation).

3. **Install dependencies:**

    ```bash
    forge install
    ```

## Smart Contract Details

### Constructor Parameters

The auction contract constructor accepts the following parameters:

- `uint256 _auctionDuration`: Duration of the auction in seconds.
- `uint256 _minBid`: Minimum bid required to participate.
- `address _vrfCoordinator`: Address of the Chainlink VRF coordinator.
- `bytes32 _gasLane`: Key hash for VRF.
- `uint64 _subscriptionId`: Subscription ID for Chainlink VRF.
- `uint32 _callbackGasLimit`: Gas limit for the VRF callback.
- `address _token`: Address of the ERC20 token to be auctioned.
- `address _initialOwner`: Address of the initial owner of the contract.

### Core Functions

- `placeBid(uint256 amount)`: Allows users to place a bid by specifying the amount.
- `endAuction()`: Ends the auction and triggers the VRF to select a random winner.
- `fulfillRandomness(bytes32 requestId, uint256 randomness)`: Internal function called by Chainlink VRF to process the random number and determine the winner.
- `transferToWinner()`: Transfers the specified ERC20 token to the auction winner.

## Running Tests

You can run the tests using Foundry's `forge test` command to ensure everything works as expected.

```bash
forge test
```

## Deployment

To deploy the contract on an Ethereum-compatible network:

1. **Compile the contracts:**

    ```bash
    forge build
    ```

2. **Deploy the contract:**

    Use a deployment script or manually deploy via the Foundry CLI. Ensure you've set the correct environment variables, especially for the VRF coordinator, gas lane, subscription ID, and token address. The deployment might look something like this:

    ```bash
    forge create --rpc-url <NETWORK_RPC_URL> --private-key <YOUR_PRIVATE_KEY> src/Auction.sol:Auction --constructor-args <auctionDuration> <minBid> <vrfCoordinator> <gasLane> <subscriptionId> <callbackGasLimit> <tokenAddress> <initialOwner>
    ```

    Replace the placeholder values with your actual parameters.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Chainlink](https://chain.link/) for the VRF functionality.
- [Foundry](https://github.com/foundry-rs/foundry) for the testing framework.
- [Patrick Collins](https://github.com/PatrickAlphaC) for his tutorials and guidance on smart contracts.

## Contact

Obed Okoh - obedokoh@gmail.com