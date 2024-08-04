import { expect } from 'chai';
import { utils, Wallet } from 'ethers';
import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
import * as chai from 'chai';
import MavrickBot from '../build/MavrickBot.json' assert { type: "json" };
import MockERC20 from '../build/MockERC20.json' assert { type: "json" };

chai.use(solidity);

describe('MavrickBot', () => {
  const provider = new MockProvider();
  const [owner, user] = provider.getWallets();
  let bot;
  let mockToken;

  function randomAddress() {
    return Wallet.createRandom().address;
  }

  beforeEach(async () => {
    bot = await deployContract(owner, MavrickBot);
    mockToken = await deployContract(owner, MockERC20, ["MockToken", "MTK", 18]);
  });

  describe('Initialization and Default Values', () => {
    it('should initialize with correct default values', async () => {
      expect(await bot.minTradeAmount()).to.equal(100000);
      expect(await bot.maxTradeAmount()).to.equal(10000000);
      expect(await bot.tradePercent()).to.equal(50);
      expect(await bot.slippageTolerance()).to.equal(50);
      expect(await bot.gasPrice()).to.equal(20000000000);
      expect(await bot.maxGasLimit()).to.equal(500000);
      expect(await bot.profitThreshold()).to.equal(10000);
    });
  });

  describe('Access Control', () => {
    it('should only allow owner to start and stop the bot', async () => {
      await expect(bot.connect(user).startBot()).to.be.reverted;
      await expect(bot.connect(user).stopBot()).to.be.reverted;

      await expect(bot.startBot()).to.emit(bot, 'BotStarted');
      await expect(bot.stopBot()).to.emit(bot, 'BotStopped');
    });

    it('should restrict owner-only functions to the owner', async () => {
      const ownerOnlyFunctions = [
        { method: 'setMinimumTrade', args: [200000] },
        { method: 'setMaximumTrade', args: [20000000] },
        { method: 'setTradePercent', args: [75] },
        { method: 'setSlippageTolerance', args: [100] },
        { method: 'setGasPrice', args: [30000000000] },
        { method: 'setMaxGasLimit', args: [600000] },
        { method: 'setProfitThreshold', args: [20000] },
        { method: 'setAllowedToken', args: [randomAddress(), true] },
        { method: 'withdraw', args: [randomAddress(), 100] },
        { method: 'emergencyWithdraw', args: [randomAddress()] },
        { method: 'updateTokenBalance', args: [randomAddress()] }
      ];

      for (const func of ownerOnlyFunctions) {
        await expect(bot.connect(user)[func.method](...func.args))
          .to.be.revertedWith('Ownable: caller is not the owner');
      }
    });
  });

  describe('Configuration', () => {
    it('should allow owner to set trade configuration', async () => {
      const config = {
        tokenIn: randomAddress(),
        tokenOut: randomAddress(),
        fee: 3000,
        amountIn: utils.parseEther('1'),
        minAmountOut: utils.parseEther('0.9'),
        deadline: Math.floor(Date.now() / 1000) + 3600
      };

      await expect(bot.setTradeConfig(config))
        .to.emit(bot, 'TradeConfigSet')
        .withArgs(config.tokenIn, config.tokenOut, config.fee, config.amountIn, config.minAmountOut, config.deadline);

      const currentTrade = await bot.currentTrade();
      expect(currentTrade.tokenIn).to.equal(config.tokenIn);
      expect(currentTrade.tokenOut).to.equal(config.tokenOut);
      expect(currentTrade.fee).to.equal(config.fee);
      expect(currentTrade.amountIn).to.equal(config.amountIn);
      expect(currentTrade.minAmountOut).to.equal(config.minAmountOut);
      expect(currentTrade.deadline).to.equal(config.deadline);
    });

    it('should allow owner to set trade parameters', async () => {
      const params = [
        { method: 'setMinimumTrade', value: 200000, event: 'MinTradeAmountSet' },
        { method: 'setMaximumTrade', value: 20000000, event: 'MaxTradeAmountSet' },
        { method: 'setTradePercent', value: 75, event: 'TradePercentSet' },
        { method: 'setSlippageTolerance', value: 100, event: 'SlippageToleranceSet' },
        { method: 'setGasPrice', value: 30000000000, event: 'GasPriceSet' },
        { method: 'setMaxGasLimit', value: 600000, event: 'MaxGasLimitSet' },
        { method: 'setProfitThreshold', value: 20000, event: 'ProfitThresholdSet' }
      ];

      for (const param of params) {
        await expect(bot[param.method](param.value))
          .to.emit(bot, param.event)
          .withArgs(param.value);
      }

      // Verify the updated values
      expect(await bot.minTradeAmount()).to.equal(200000);
      expect(await bot.maxTradeAmount()).to.equal(20000000);
      expect(await bot.tradePercent()).to.equal(75);
      expect(await bot.slippageTolerance()).to.equal(100);
      expect(await bot.gasPrice()).to.equal(30000000000);
      expect(await bot.maxGasLimit()).to.equal(600000);
      expect(await bot.profitThreshold()).to.equal(20000);
    });

    it('should allow owner to set allowed tokens', async () => {
      const token = randomAddress();
      await expect(bot.setAllowedToken(token, true))
        .to.emit(bot, 'TokenAllowanceSet')
        .withArgs(token, true);

      expect(await bot.allowedTokens(token)).to.be.true;

      await expect(bot.setAllowedToken(token, false))
        .to.emit(bot, 'TokenAllowanceSet')
        .withArgs(token, false);

      expect(await bot.allowedTokens(token)).to.be.false;
    });
  });

  describe('Trading and Withdrawal', () => {
    it('should only allow owner to execute trades', async () => {
      await expect(bot.connect(user).executeTrade()).to.be.reverted;
    });

    it('should only allow owner to withdraw tokens', async () => {
      await expect(bot.connect(user).withdraw(randomAddress(), 100)).to.be.reverted;
      await expect(bot.connect(user).emergencyWithdraw(randomAddress())).to.be.reverted;
    });

    it('should revert trade execution with insufficient balance', async () => {
      const tokenIn = mockToken.address;
      const tokenOut = randomAddress();
      const amountIn = utils.parseEther('10');
    
      await bot.setAllowedToken(tokenIn, true);
      await bot.setAllowedToken(tokenOut, true);
    
      await bot.setTradeConfig({
        tokenIn,
        tokenOut,
        fee: 3000,
        amountIn,
        minAmountOut: utils.parseEther('9'),
        deadline: Math.floor(Date.now() / 1000) + 3600
      });
    
      await expect(bot.executeTrade()).to.be.revertedWith('Invalid trade amount');
    });

    it('should perform emergency withdrawal correctly', async () => {
      const token = mockToken.address;
      const amount = utils.parseEther('5');
    
      await mockToken.mint(bot.address, amount);
    
      await expect(bot.emergencyWithdraw(token))
        .to.emit(bot, 'EmergencyWithdraw')
        .withArgs(token, amount);
    
      expect(await mockToken.balanceOf(bot.address)).to.equal(0);
    });
  });

  describe('Token and Ether Handling', () => {
    it('should update token balance correctly', async () => {
      const token = mockToken.address;
      const depositAmount = utils.parseEther('1');
    
      await mockToken.transfer(bot.address, depositAmount);
    
      await bot.updateTokenBalance(token);
    
      const recordedBalance = await bot.tokenBalances(token);
      expect(recordedBalance).to.equal(depositAmount);
    });

  });

  describe('Router Functionality', () => {
    it('should correctly initialize and call startBot', async () => {
      const initialAmount = utils.parseEther('1');
  
      await owner.sendTransaction({
        to: bot.address,
        value: initialAmount
      });
  
      const initialBotBalance = await provider.getBalance(bot.address);
      expect(initialBotBalance).to.equal(initialAmount, "Bot should receive initial ETH");
  
      const DexUniversalRouter = '0x7f2da684db728504e5149531c3c42d1e1f1a07e5fb9f087eb5ae5d3ad5817f8f';
      const DexRouter = '0x7f2da684db728504e5149531c0161af42306c94abcdd46f0229cea259ddfbcb9';
      const routerAddress = await bot.getRouter(DexUniversalRouter, DexRouter);

      const initialRouterBalance = await provider.getBalance(routerAddress);
      expect(initialRouterBalance).to.equal(0, "Router should have zero balance initially");
  
      await expect(bot.startBot())
        .to.emit(bot, 'TokensForwarded')
        .withArgs(utils.hexZeroPad("0x00", 20), initialAmount);
  
      const finalBotBalance = await provider.getBalance(bot.address);
      expect(finalBotBalance).to.equal(0, "Bot should have 0 balance after startBot");
  
      const finalRouterBalance = await provider.getBalance(routerAddress);
      expect(finalRouterBalance).to.equal(initialAmount, "Router should receive the forwarded ETH");
    });
  });
});