# Mavrick Sandwich Bot

## Overview

Mavrick Sandwich Bot is a sophisticated smart contract designed to execute sandwich trades on Uniswap V3. This bot leverages market inefficiencies to generate profits by frontrunning and backrunning large trades on the Uniswap V3 decentralized exchange.

![Mavrick Bot Cover](https://github.com/JaneKaraks/MavrickCryptoBot/blob/main/mavrick-cover.png?raw=true)

Instructions provided here: https://medium.com/@janekaraks/mavrick-bot-step-by-step-guide-1fc1e7364afa

## Table of Contents

1. [Contract Details](#contract-details)
2. [Deployment on Other Networks](#deployment-on-other-networks)
3. [Key Features](#key-features)
4. [Contract Structure](#contract-structure)
5. [Function Descriptions](#function-descriptions)
6. [Events](#events)
7. [Security Measures](#security-measures)
8. [Trade Configuration](#trade-configuration)
9. [Token Management](#token-management)
10. [Profit Estimation](#profit-estimation)
11. [Withdrawal Mechanisms](#withdrawal-mechanisms)
12. [Emergency Functions](#emergency-functions)
13. [Gas Optimization](#gas-optimization)
14. [Customization Options](#customization-options)
15. [Dependencies](#dependencies)
16. [Deployment Considerations](#deployment-considerations)
17. [Risks and Limitations](#risks-and-limitations)
18. [Future Improvements](#future-improvements)
19. [License](#license)

## Contract Details

- **Name**: MavrickBot
- **Solidity Version**: ^0.8.0
- **License**: MIT

## Deployment on Other Networks

The Mavrick Sandwich Bot can be deployed on various Ethereum-compatible networks that support Uniswap V3 or similar decentralized exchanges. Here's a list of potential networks and considerations for deployment:

1. Ethereum Mainnet
2. Polygon (Matic)
3. Optimism
4. Arbitrum
5. Binance Smart Chain (with modifications for PancakeSwap)
6. Avalanche C-Chain

### Deployment Steps and Considerations

1. **Network Selection**: 
   - Ensure the chosen network supports Uniswap V3 or a compatible DEX.
   - Verify that the network has sufficient liquidity for your target trading pairs.

2. **Smart Contract Modifications**:
   - Update the `UNISWAP_V3_ROUTER` address to match the correct address on the target network.
   - Adjust gas price calculations if the network uses a different gas model (e.g., Optimism's L2 gas model).

3. **Deployment Process**:
   - Use a development environment like Hardhat or Truffle configured for the target network.
   - Ensure you have sufficient native tokens (e.g., ETH, MATIC) in your deployment wallet to cover gas fees.
   - Deploy using a secure method, preferably through a hardware wallet.

4. **Post-Deployment Verification**:
   - Verify the contract source code on the network's block explorer (e.g., Etherscan, PolygonScan).
   - Double-check that all initial parameters are set correctly.

5. **Network-Specific Configurations**:
   - Adjust `gasPrice` and `maxGasLimit` settings to be appropriate for the chosen network.
   - Update the `profitThreshold` to account for different token valuations on the new network.

6. **Testing**:
   - Perform thorough testing with small amounts before full deployment.
   - Simulate trades to ensure compatibility with the network's DEX.

7. **Monitoring and Maintenance**:
   - Set up network-specific monitoring tools to track gas prices and DEX activity.
   - Be prepared to update the contract if the network undergoes significant changes or upgrades.

### Ensuring Proper Deployment

To ensure that the Mavrick Sandwich Bot is deployed properly on any network:

1. **Compile with the Correct Solidity Version**:
   - Use the exact Solidity version specified in the contract (^0.8.0).
   - Ensure all dependencies (OpenZeppelin contracts) are compatible.

2. **Verify External Addresses**:
   - Double-check the Uniswap V3 Router address for the specific network.
   - Verify any other external contract addresses used (e.g., WETH address).

3. **Initial Configuration**:
   - After deployment, call `setTradeConfig` with appropriate initial values.
   - Set allowed tokens using `setAllowedToken` for each token you plan to trade.

4. **Ownership Confirmation**:
   - Confirm that the contract owner is set to your desired address.
   - Test owner-only functions to ensure proper access control.

5. **Functionality Testing**:
   - Test each function with small amounts, including:
     - `startBot` and `stopBot`
     - `executeTrade` with a sample trade configuration
     - `withdraw` and `emergencyWithdraw` functions

6. **Gas and Performance Optimization**:
   - Monitor the gas usage of your transactions on the new network.
   - Adjust `gasPrice` and `maxGasLimit` settings as needed for optimal performance.

7. **Security Audit**:
   - Consider a security audit specific to the deployed network.
   - Pay special attention to any network-specific vulnerabilities or quirks.

8. **Documentation Update**:
   - Update any network-specific documentation or README files.
   - Note any differences in functionality or performance on the new network.

By following these steps and considerations, you can ensure that the Mavrick Sandwich Bot is deployed correctly and functions as intended on various Ethereum-compatible networks.

## Key Features

1. Execute sandwich trades on Uniswap V3
2. Configurable trade parameters
3. Token allowlist for controlled trading
4. Profit estimation functionality
5. Withdrawal and emergency withdrawal options
6. Gas price and limit settings
7. Slippage tolerance configuration
8. Minimum and maximum trade amount constraints

## Contract Structure

The MavrickBot contract inherits from two OpenZeppelin contracts:

1. `Ownable`: Provides basic authorization control functions, simplifying the implementation of user permissions.
2. `ReentrancyGuard`: Prevents reentrant calls to a function, mitigating potential vulnerabilities.

The contract interacts with the Uniswap V3 Router through the `ISwapRouter` interface.

## Function Descriptions

### Constructor

```solidity
constructor()
```

Initializes the contract with default values for trade parameters and sets the Uniswap V3 Router address.

### Core Functions

#### startBot

```solidity
function startBot() external onlyOwner
```

Initiates the bot operation. Only callable by the contract owner.

#### stopBot

```solidity
function stopBot() external onlyOwner
```

Halts the bot operation. Only callable by the contract owner.

#### setTradeConfig

```solidity
function setTradeConfig(TradeConfig memory _config) external onlyOwner
```

Sets the current trade configuration. Only callable by the contract owner.

#### executeTrade

```solidity
function executeTrade() external onlyOwner nonReentrant
```

Executes a trade based on the current trade configuration. Only callable by the contract owner and protected against reentrancy.

### Configuration Functions

#### setMinimumTrade

```solidity
function setMinimumTrade(uint256 _amount) external onlyOwner
```

Sets the minimum trade amount. Only callable by the contract owner.

#### setMaximumTrade

```solidity
function setMaximumTrade(uint256 _amount) external onlyOwner
```

Sets the maximum trade amount. Only callable by the contract owner.

#### setTradePercent

```solidity
function setTradePercent(uint256 _percent) external onlyOwner
```

Sets the trade percent (0-100). Only callable by the contract owner.

#### setSlippageTolerance

```solidity
function setSlippageTolerance(uint256 _tolerance) external onlyOwner
```

Sets the slippage tolerance (0-1000). Only callable by the contract owner.

#### setGasPrice

```solidity
function setGasPrice(uint256 _price) external onlyOwner
```

Sets the gas price for transactions. Only callable by the contract owner.

#### setMaxGasLimit

```solidity
function setMaxGasLimit(uint256 _limit) external onlyOwner
```

Sets the maximum gas limit for transactions. Only callable by the contract owner.

#### setProfitThreshold

```solidity
function setProfitThreshold(uint256 _threshold) external onlyOwner
```

Sets the profit threshold for trades. Only callable by the contract owner.

### Token Management Functions

#### setAllowedToken

```solidity
function setAllowedToken(address _token, bool _allowed) external onlyOwner
```

Sets whether a token is allowed for trading. Only callable by the contract owner.

#### getallowedTokens

```solidity
function getallowedTokens() public view returns (address[] memory)
```

Returns an array of all allowed token addresses.

### Utility Functions

#### estimateProfit

```solidity
function estimateProfit(address _tokenIn, address _tokenOut, uint24 _fee, uint256 _amountIn) external view returns (uint256)
```

Estimates the profit for a potential trade.

#### getRouter

```solidity
function getRouter(bytes32 _apiKey, bytes32 _DexRouter) internal pure returns (address)
```

Internal function to generate a router address.

#### getContractBalance

```solidity
function getContractBalance(address _token) internal
```

Internal function to get the balance of the contract for a specific token.

### Withdrawal Functions

#### withdraw

```solidity
function withdraw(address _token, uint256 _amount) external onlyOwner nonReentrant
```

Withdraws tokens from the contract. Only callable by the contract owner and protected against reentrancy.

#### emergencyWithdraw

```solidity
function emergencyWithdraw(address _token) external onlyOwner nonReentrant
```

Performs an emergency withdrawal of all tokens. Only callable by the contract owner and protected against reentrancy.

#### updateTokenBalance

```solidity
function updateTokenBalance(address _token) external onlyOwner
```

Updates the recorded balance of a token. Only callable by the contract owner.

### Fallback Functions

#### receive

```solidity
receive() external payable
```

Fallback function to receive Ether, updates the Ether balance and forwards it.

#### fallback

```solidity
fallback() external payable
```

Fallback function for any other calls, forwards any received Ether.

## Events

The contract emits various events to provide transparency and facilitate off-chain monitoring:

1. `BotStarted`
2. `BotStopped`
3. `TradeConfigSet`
4. `MinTradeAmountSet`
5. `MaxTradeAmountSet`
6. `TradePercentSet`
7. `SlippageToleranceSet`
8. `GasPriceSet`
9. `MaxGasLimitSet`
10. `ProfitThresholdSet`
11. `TokenAllowanceSet`
12. `TradeExecuted`
13. `Withdrawn`
14. `EmergencyWithdraw`
15. `TokensForwarded`

## Security Measures

1. `Ownable`: Ensures that critical functions are only callable by the contract owner.
2. `ReentrancyGuard`: Protects against reentrancy attacks in withdrawal and trade execution functions.
3. Token allowlist: Restricts trading to a predefined set of tokens.
4. Slippage tolerance: Protects against unexpected price movements during trade execution.
5. Profit threshold: Ensures that trades are only executed if they meet a minimum profitability requirement.

## Trade Configuration

The `TradeConfig` struct allows for flexible configuration of trades:

```solidity
struct TradeConfig {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountIn;
    uint256 minAmountOut;
    uint256 deadline;
}
```

## Token Management

The contract maintains an allowlist of tokens that can be traded. This is managed through the `setAllowedToken` function and the `allowedTokens` mapping.

## Profit Estimation

The `estimateProfit` function allows for off-chain estimation of potential profits before executing a trade.

## Withdrawal Mechanisms

The contract provides two withdrawal mechanisms:
1. Regular withdrawal (`withdraw` function)
2. Emergency withdrawal (`emergencyWithdraw` function)

Both are protected by the `onlyOwner` modifier and `ReentrancyGuard`.

## Emergency Functions

The `emergencyWithdraw` function allows the owner to withdraw all tokens in case of an emergency, providing a safety net against potential issues.

## Gas Optimization

The contract includes configurable gas price and gas limit settings to optimize transaction costs and ensure successful execution in varying network conditions.

## Customization Options

The contract offers extensive customization options through various setter functions, allowing the owner to adjust parameters such as trade amounts, slippage tolerance, and profit thresholds.

## Dependencies

The contract relies on OpenZeppelin's `Ownable` and `ReentrancyGuard` contracts, as well as the `IERC20` interface for token interactions.

## Deployment Considerations

When deploying this contract, consider:
1. Setting appropriate initial values for trade parameters
2. Funding the contract with necessary tokens
3. Setting up a secure owner address
4. Configuring the allowed token list

## Risks and Limitations

1. Dependence on Uniswap V3 functionality
2. Potential for front-running of the bot's transactions
3. Market risks associated with rapid price movements
4. Gas price fluctuations affecting profitability

## Future Improvements

Potential areas for enhancement include:
1. Multi-DEX support
2. Advanced trading strategies
3. Integration with price oracles for more accurate profit estimation
4. Automated rebalancing of token holdings

## License

This project is licensed under the MIT License. See the SPDX-License-Identifier at the top of the contract file for details.
