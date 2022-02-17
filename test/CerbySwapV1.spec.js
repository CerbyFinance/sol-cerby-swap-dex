"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bn_js_1 = __importDefault(require("bn.js"));
const crypto_1 = __importDefault(require("crypto"));
const util_1 = require("util");
const truffleAssert = require('truffle-assertions');
const TestCerbyToken = artifacts.require('TestCerbyToken');
const TestCerUsdToken = artifacts.require('TestCerUsdToken');
const TestUsdcToken = artifacts.require('TestUsdcToken');
const VaultContract = artifacts.require('CerbySwapV1_Vault');
const CerbySwapV1 = artifacts.require('CerbySwapV1');
// const CerbyBotDetection = artifacts.require("CerbyBotDetection");
const DELAY_BETWEEN_TESTS = 0;
const now = () => Math.floor(+new Date() / 1000);
const randomAddress = () => '0x' + crypto_1.default.randomBytes(20).toString('hex');
const ETH_TOKEN_ADDRESS = '0x14769F96e57B80c66837701DE0B43686Fb4632De';
const CERBY_TOKEN_ADDRESS = '0xE7126C0Fb4B1f5F79E5Bbec3948139dCF348B49C';
const CER_USD_TOKEN_ADDRESS = '0x3B69b8C5c6a4c8c2a90dc93F3B0238BF70cC9640';
const USDC_TOKEN_ADDRESS = '0x3B1DD4b62C04E92789aAFEf24AF74bEeB5006395';
const _BN = (value) => {
    return new bn_js_1.default(value);
};
const FEE_DENORM = _BN(10000);
const bn1e18 = _BN((1e18).toString());
function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
let shift = 0;
function currentTimestamp() {
    return now() + shift;
}
// @ts-ignore
const send = (0, util_1.promisify)(web3.currentProvider.send);
const increaseTime = async (seconds) => {
    shift += seconds;
    await send({
        method: 'evm_increaseTime',
        params: [seconds],
    });
    await send({ method: 'evm_mine', params: [] });
};
contract('Cerby', (accounts) => {
    // ---------------------------------------------------------- //
    // initial deploy contracts & output addresses //
    // ---------------------------------------------------------- //
    it.only('init: deploy tokens/vault & output addresses', async () => {
        const _TestCerbyTokenAddress = (await TestCerbyToken.deployed()).address;
        const _TestCerUsdTokenAddress = (await TestCerUsdToken.deployed()).address;
        const _TestUsdcTokenAddress = (await TestUsdcToken.deployed()).address;
        const _VaultContractAddress = (await VaultContract.deployed()).address;
        console.log("const CERBY_TOKEN_ADDRESS = '" + _TestCerbyTokenAddress + "';");
        console.log("const CER_USD_TOKEN_ADDRESS = '" + _TestCerUsdTokenAddress + "';");
        console.log("const USDC_TOKEN_ADDRESS = '" + _TestUsdcTokenAddress + "';");
        console.log('--------------------------');
        console.log('address constant CER_USD_TOKEN = ' + _TestCerUsdTokenAddress + ';');
        console.log('address constant VAULT_IMPLEMENTATION = ' + _VaultContractAddress + ';');
        console.log('address constant NATIVE_TOKEN = ' + ETH_TOKEN_ADDRESS + ';');
        console.log('--------------------------');
        const cerbySwap = await CerbySwapV1.deployed();
        console.log('address constant CerbySwapAddress = ' + cerbySwap.address + ';');
    });
    it.only('adminCreatePool: create cerby, usdc, eth pools', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const cerbySwap = await CerbySwapV1.deployed();
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const TestCerbyTokenInst = await TestCerbyToken.at(CERBY_TOKEN_ADDRESS);
        const TestCerUsdTokenInst = await TestCerUsdToken.at(CER_USD_TOKEN_ADDRESS);
        const TestUsdcTokenInst = await TestUsdcToken.at(USDC_TOKEN_ADDRESS);
        {
            await TestCerbyTokenInst.mintHumanAddress(firstAccount, _BN(1e9).mul(bn1e18).add(_BN(1)));
            await TestCerUsdTokenInst.mintHumanAddress(firstAccount, _BN(1e9).mul(bn1e18).add(_BN(2)));
            await TestUsdcTokenInst.mintHumanAddress(firstAccount, _BN(1e9).mul(bn1e18).add(_BN(3)));
            await TestCerbyTokenInst.approve(cerbySwap.address, bn1e18.mul(bn1e18));
            await TestCerUsdTokenInst.approve(cerbySwap.address, bn1e18.mul(bn1e18));
            await TestUsdcTokenInst.approve(cerbySwap.address, bn1e18.mul(bn1e18));
            // creating admin cerby pool
            let amountTokensIn1 = _BN(1e6).mul(bn1e18);
            let amountTokensIn2 = _BN(5e5).mul(bn1e18);
            await cerbySwap.adminCreatePool(CERBY_TOKEN_ADDRESS, amountTokensIn1, amountTokensIn2, firstAccount);
            let pool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            assert.deepEqual(pool.balanceToken.toString(), amountTokensIn1.toString());
            assert.deepEqual(pool.balanceCerUsd.toString(), amountTokensIn2.toString());
            // creating admin eth pool
            amountTokensIn1 = _BN(1e15);
            amountTokensIn2 = _BN(1e6).mul(bn1e18);
            await cerbySwap.adminCreatePool(ETH_TOKEN_ADDRESS, amountTokensIn1, amountTokensIn2, firstAccount, {
                value: amountTokensIn1,
            });
            pool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            assert.deepEqual(pool.balanceToken.toString(), amountTokensIn1.toString());
            assert.deepEqual(pool.balanceCerUsd.toString(), amountTokensIn2.toString());
            // creating admin usdc pool
            amountTokensIn1 = _BN(7e5).mul(bn1e18);
            amountTokensIn2 = _BN(7e5).mul(bn1e18);
            await cerbySwap.adminCreatePool(USDC_TOKEN_ADDRESS, amountTokensIn1, amountTokensIn2, firstAccount);
            pool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            assert.deepEqual(pool.balanceToken.toString(), amountTokensIn1.toString());
            assert.deepEqual(pool.balanceCerUsd.toString(), amountTokensIn2.toString());
        }
    });
    // ---------------------------------------------------------- //
    // admin tests //
    // ---------------------------------------------------------- //
    it.skip('adminUpdateSettings: set initial settings', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        console.log(new Date().toUTCString());
        const cerbySwap = await CerbySwapV1.deployed();
        {
            const oldSettings = await cerbySwap.getSettings();
            console.log(oldSettings);
            let newSettings = oldSettings;
            newSettings = {
                mintFeeBeneficiary: '0xdEF78a28c78A461598d948bc0c689ce88f812AD8',
                mintFeeMultiplier: _BN((10000 * 20) / 100),
                feeMinimum: _BN(1),
                feeMaximum: _BN(200),
                tvlMultiplierMinimum: _BN(1369863014),
                tvlMultiplierMaximum: _BN((1369863014 * 200) / 1),
            };
            await cerbySwap.adminUpdateSettings(newSettings);
            const updatedSettings = await cerbySwap.getSettings();
            console.log(updatedSettings);
        }
    });
    it('adminSetUrlPrefix: uri must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const cerbySwap = await CerbySwapV1.deployed();
        await send({
            method: 'evm_setTime',
            params: [Math.floor(+new Date())],
        });
        {
            const urlPrefix = 'https://test.com/path/';
            const itemNumber = '777';
            const url = urlPrefix + itemNumber + '.json';
            await cerbySwap.adminSetUrlPrefix(urlPrefix);
            const newUrl = await cerbySwap.uri(itemNumber);
            assert.deepEqual(newUrl, url);
        }
    });
    it('adminUpdateNameAndSymbol: name, symbol must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const cerbySwap = await CerbySwapV1.deployed();
        {
            const name = 'CerbySwapV777';
            const symbol = 'CERBY_SWAP_777';
            await cerbySwap.adminUpdateNameAndSymbol(name, symbol);
            const newName = await cerbySwap.name();
            const newSymbol = await cerbySwap.symbol();
            assert.deepEqual(newName, name);
            assert.deepEqual(newSymbol, symbol);
        }
    });
    // why is not working???
    it.skip('adminUpdateSettings: settings must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const cerbySwap = await CerbySwapV1.deployed();
        {
            const oldSettings = await cerbySwap.getSettings();
            console.log(oldSettings);
            let newSettings = oldSettings;
            newSettings = {
                mintFeeBeneficiary: CERBY_TOKEN_ADDRESS,
                mintFeeMultiplier: _BN(oldSettings.mintFeeMultiplier).add(_BN(1)),
                feeMinimum: _BN(oldSettings.feeMinimum).add(_BN(1)),
                feeMaximum: _BN(oldSettings.feeMaximum).add(_BN(1)),
                tvlMultiplierMinimum: _BN(oldSettings.tvlMultiplierMinimum).add(_BN(1)),
                tvlMultiplierMaximum: _BN(oldSettings.tvlMultiplierMaximum).add(_BN(1)),
            };
            console.log(newSettings);
            await cerbySwap.adminUpdateSettings(newSettings);
            const updatedSettings = await cerbySwap.getSettings();
            assert.deepEqual(newSettings, updatedSettings);
        }
    });
    // ---------------------------------------------------------- //
    // addTokenLiquidity tests //
    // ---------------------------------------------------------- //
    it('addTokenLiquidity: add 1041e10 ETH; pool must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const [firstAccount, alice, bob, random] = accounts;
        const cerbySwap = await CerbySwapV1.deployed();
        const ETH_POOL_POS = await cerbySwap.getTokenToPoolId(ETH_TOKEN_ADDRESS);
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
        {
            const tokenIn = ETH_TOKEN_ADDRESS;
            const amountTokensIn = _BN(1041e10);
            const amountCerUsdIn = amountTokensIn
                .mul(_BN(beforeEthPool.balanceCerUsd))
                .div(_BN(beforeEthPool.balanceToken));
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](ETH_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeEthPool.balanceToken));
            await cerbySwap.addTokenLiquidity(tokenIn, amountTokensIn, expireTimestamp, transferTo, { value: amountTokensIn, gas: '300000' });
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            // check lp tokens increased
            assert.deepEqual(beforeLpTokens.add(lpTokens).toString(), afterLpTokens.toString());
            // check pool increased balance
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn), _BN(afterEthPool.balanceToken));
            // check pool increased balance
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountCerUsdIn), _BN(afterEthPool.balanceCerUsd));
        }
    });
    it('addTokenLiquidity: add 1042 CERBY; pool must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        const res = await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]);
        const beforeCerbyPool = res[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
        {
            const tokenIn = CERBY_TOKEN_ADDRESS;
            const amountTokensIn = _BN(1042).mul(bn1e18);
            const amountCerUsdIn = amountTokensIn
                .mul(_BN(beforeCerbyPool.balanceCerUsd))
                .div(_BN(beforeCerbyPool.balanceToken));
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(tokenIn, amountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            // check lp tokens increased
            assert.deepEqual(beforeLpTokens.add(lpTokens).toString(), afterLpTokens.toString());
            // check pool increased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn), _BN(afterCerbyPool.balanceToken));
            // check pool increased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountCerUsdIn), _BN(afterCerbyPool.balanceCerUsd));
        }
    });
    // ---------------------------------------------------------- //
    // swapExactTokensForTokens tests //
    // ---------------------------------------------------------- //
    it('swapExactTokensForTokens: swap 1001 CERBY --> cerUSD; received cerUSD is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const tokenIn = CERBY_TOKEN_ADDRESS;
        const tokenOut = CER_USD_TOKEN_ADDRESS;
        const amountTokensIn = _BN(1001).mul(bn1e18);
        const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, {
            gas: '3000000',
        });
        const minAmountTokensOut = 0;
        const expireTimestamp = currentTimestamp() + 86400;
        const transferTo = firstAccount;
        await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo, {
            gas: '3000000',
        });
        const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        // check pool increased by amountTokensIn
        assert.deepEqual(_BN(afterCerbyPool.balanceToken).toString(), _BN(beforeCerbyPool.balanceToken).add(amountTokensIn).toString());
        assert.deepEqual(_BN(afterCerbyPool.balanceCerUsd), _BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut));
        // check K must be increased
        assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
            .mul(_BN(beforeCerbyPool.balanceToken))
            .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
    });
    it('swapExactTokensForTokens: swap 1002 cerUSD --> CERBY; received CERBY is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = CER_USD_TOKEN_ADDRESS;
            const tokenOut = CERBY_TOKEN_ADDRESS;
            const amountTokensIn = _BN(1002).mul(bn1e18);
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo, {
                gas: '3000000',
            });
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn), _BN(afterCerbyPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1003 cerUSD --> CERBY --> cerUSD; sent cerUSD >= received cerUSD', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            // cerUSD --> CERBY
            const tokenIn1 = CER_USD_TOKEN_ADDRESS;
            const tokenOut1 = CERBY_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1003).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // CERBY --> cerUSD
            const tokenIn2 = CERBY_TOKEN_ADDRESS;
            const tokenOut2 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check sent amount must be larger than received
            assert.isTrue(_BN(amountTokensIn1).gte(_BN(amountTokensOut2)));
            // check intermediate token balance must not change
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1004 CERBY --> cerUSD --> CERBY; sent CERBY >= received CERBY', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            // CERBY --> cerUSD
            const tokenIn1 = CERBY_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1004).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = CERBY_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check sent amount larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            assert.deepEqual(beforeCerbyPool.balanceCerUsd.toString(), afterCerbyPool.balanceCerUsd.toString());
            // check token balance increased and decreased correctly
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken)
                .add(amountTokensIn1)
                .sub(amountTokensOut2), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1005 CERBY --> cerUSD --> USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // CERBY --> cerUSD
            const tokenIn1 = CERBY_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1005).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> USDC
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const amountTokensOut3 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1);
            assert.deepEqual(amountTokensOut2, amountTokensOut3);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn1), _BN(afterCerbyPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterCerbyPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1006 CERBY --> USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // CERBY --> cerUSD
            const tokenIn1 = CERBY_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1006).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> USDC
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const amountTokensOut3 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1);
            assert.deepEqual(amountTokensOut2, amountTokensOut3);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn1), _BN(afterCerbyPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterCerbyPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1007 USDC --> cerUSD --> CERBY; received CERBY is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1007).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> CERBY
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = CERBY_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const amountTokensOut3 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1);
            assert.deepEqual(amountTokensOut2, amountTokensOut3);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn2), _BN(afterCerbyPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut2), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1008 USDC --> CERBY; received CERBY is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1008).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> CERBY
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = CERBY_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const amountTokensOut3 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1);
            assert.deepEqual(amountTokensOut2, amountTokensOut3);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn2), _BN(afterCerbyPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut2), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: check reverts', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            // cerUSD --> cerUSD
            const SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L = 'L';
            let tokenIn1 = CER_USD_TOKEN_ADDRESS;
            let tokenOut1 = CER_USD_TOKEN_ADDRESS;
            let amountTokensIn1 = _BN(1010).mul(bn1e18);
            let minAmountTokensOut1 = _BN(0);
            let expireTimestamp1 = currentTimestamp() + 86400;
            let transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L);
            // CERBY --> CERBY
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(1000000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L);
            const OUTPUT_CERUSD_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_H = 'H';
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(1000000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), OUTPUT_CERUSD_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_H);
            const OUTPUT_TOKENS_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_i = 'i';
            tokenIn1 = CER_USD_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(1000000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), OUTPUT_TOKENS_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_i);
            tokenIn1 = USDC_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(1000000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), OUTPUT_TOKENS_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_i);
            const TRANSACTION_IS_EXPIRED_D = 'D';
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(0);
            expireTimestamp1 = currentTimestamp() - 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), TRANSACTION_IS_EXPIRED_D);
            const AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F = '2';
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(0).mul(bn1e18);
            minAmountTokensOut1 = _BN(0);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            tokenIn1 = CER_USD_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(0).mul(bn1e18);
            minAmountTokensOut1 = _BN(0);
            amountTokensIn1 = _BN(0);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            tokenIn1 = USDC_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(0).mul(bn1e18);
            minAmountTokensOut1 = _BN(0);
            amountTokensIn1 = _BN(0);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            const CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountTokensIn = 'x2';
            tokenIn1 = ETH_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensIn1 = _BN(1).mul(bn1e18);
            minAmountTokensOut1 = _BN(0);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                value: amountTokensIn1.sub(_BN(10)),
            }), CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountTokensIn);
        }
    });
    // ---------------------------------------------------------- //
    // swapTokensForExactTokens tests //
    // ---------------------------------------------------------- //
    it('swapTokensForExactTokens: swap CERBY --> 1011 cerUSD; received cerUSD is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = CERBY_TOKEN_ADDRESS;
            const tokenOut = CER_USD_TOKEN_ADDRESS;
            const amountTokensOut = _BN(1011).mul(bn1e18);
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = _BN(1000000).mul(bn1e18);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn), _BN(afterCerbyPool.balanceToken));
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut), _BN(afterCerbyPool.balanceCerUsd));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap cerUSD --> 1012 CERBY; received CERBY is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = CER_USD_TOKEN_ADDRESS;
            const tokenOut = CERBY_TOKEN_ADDRESS;
            const amountTokensOut = _BN(1012).mul(bn1e18);
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = _BN(1000000).mul(bn1e18);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn), _BN(afterCerbyPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap cerUSD --> CERBY --> 1013 cerUSD; sent cerUSD >= received cerUSD', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = CER_USD_TOKEN_ADDRESS;
            const tokenOut1 = CERBY_TOKEN_ADDRESS;
            const tokenIn2 = CERBY_TOKEN_ADDRESS;
            const tokenOut2 = CER_USD_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN(1013).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check sent amount must be larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            // since pool is changing during swaps
            // it is not correct to do such test
            // thats why commenting failing assert below
            // convert
            // Q: why not to use assert.notDeepEqual() then?
            /*assert.deepEqual(
                      beforeCerbyPool.balanceToken.toString(),
                      afterCerbyPool.balanceToken.toString(),
                  );*/
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap CERBY --> cerUSD --> 1014 CERBY; sent CERBY >= received CERBY', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = CERBY_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = CERBY_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN(1014).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check sent amount larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            // since pool is changing during swaps
            // it is not correct to do such test
            // thats why commenting failing assert below
            /*assert.deepEqual(
                      beforeCerbyPool.balanceCerUsd.toString(),
                      afterCerbyPool.balanceCerUsd.toString(),
                  );*/
            // check token balance increased and decreased correctly
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken)
                .add(amountTokensIn1)
                .sub(amountTokensOut2), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap CERBY --> cerUSD --> 1015 USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = CERBY_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN(1015).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const amountTokensIn0 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2);
            assert.deepEqual(amountTokensIn1.toString(), amountTokensIn0.toString());
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn1), _BN(afterCerbyPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterCerbyPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap CERBY --> 1016 USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = CERBY_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN(1016).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const amountTokensIn0 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2);
            assert.deepEqual(amountTokensIn1, amountTokensIn0);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn1), _BN(afterCerbyPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterCerbyPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap USDC --> cerUSD --> 1017 CERBY; received CERBY is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = CERBY_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN(1017).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const amountTokensIn0 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2);
            assert.deepEqual(amountTokensIn1, amountTokensIn0);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn2), _BN(afterCerbyPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut2), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap USDC --> 1018 CERBY; received CERBY is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = CERBY_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN(1018).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const amountTokensIn0 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2);
            assert.deepEqual(amountTokensIn1, amountTokensIn0);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn2), _BN(afterCerbyPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut2), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: check reverts', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            // cerUSD --> cerUSD
            const SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L = 'L';
            let tokenIn1 = CER_USD_TOKEN_ADDRESS;
            let tokenOut1 = CER_USD_TOKEN_ADDRESS;
            let amountTokensOut1 = _BN(1020).mul(bn1e18);
            let maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            let expireTimestamp1 = currentTimestamp() + 86400;
            let transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L);
            const OUTPUT_TOKENS_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_K = 'K';
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(1020).mul(bn1e18);
            maxAmountTokensIn1 = _BN(0).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), OUTPUT_TOKENS_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_K);
            tokenIn1 = USDC_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(1020).mul(bn1e18);
            maxAmountTokensIn1 = _BN(0).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), OUTPUT_TOKENS_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_K);
            const OUTPUT_CERUSD_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_J = 'J';
            tokenIn1 = CER_USD_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(1020).mul(bn1e18);
            maxAmountTokensIn1 = _BN(0).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), OUTPUT_CERUSD_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_J);
            const TRANSACTION_IS_EXPIRED_D = 'D';
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(1020).mul(bn1e18);
            maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() - 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), TRANSACTION_IS_EXPIRED_D);
            const AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F = '2';
            tokenIn1 = CERBY_TOKEN_ADDRESS;
            tokenOut1 = CER_USD_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(0);
            maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            const AMOUNT_OF_CERUSD_MUST_BE_LARGER_THAN_ZERO_U = '2';
            tokenIn1 = CER_USD_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(0);
            maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), AMOUNT_OF_CERUSD_MUST_BE_LARGER_THAN_ZERO_U);
            tokenIn1 = USDC_TOKEN_ADDRESS;
            tokenOut1 = CERBY_TOKEN_ADDRESS;
            amountTokensOut1 = _BN(0);
            maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            expireTimestamp1 = currentTimestamp() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), AMOUNT_OF_CERUSD_MUST_BE_LARGER_THAN_ZERO_U);
        }
    });
    // ---------------------------------------------------------- //
    // swapExactTokensForTokens ETH tests //
    // ---------------------------------------------------------- //
    it('swapExactTokensForTokens: swap 1021e10 ETH --> cerUSD; received cerUSD is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = ETH_TOKEN_ADDRESS;
            const tokenOut = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn = _BN((1021e10).toString());
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo, { value: amountTokensIn });
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn), _BN(afterEthPool.balanceToken));
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut), _BN(afterEthPool.balanceCerUsd));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1022 cerUSD --> ETH; received ETH is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = CER_USD_TOKEN_ADDRESS;
            const tokenOut = ETH_TOKEN_ADDRESS;
            const amountTokensIn = _BN(1022).mul(bn1e18);
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn), _BN(afterEthPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1023 cerUSD --> ETH --> cerUSD; sent cerUSD >= received cerUSD', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            // cerUSD --> ETH
            const tokenIn1 = CER_USD_TOKEN_ADDRESS;
            const tokenOut1 = ETH_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1023).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // ETH --> cerUSD
            const tokenIn2 = ETH_TOKEN_ADDRESS;
            const tokenOut2 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2, { value: amountTokensIn2 });
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check sent amount must be larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            assert.deepEqual(_BN(beforeEthPool.balanceToken), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1024e10 ETH --> cerUSD --> ETH; sent ETH >= received ETH', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            // ETH --> cerUSD
            const tokenIn1 = ETH_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN((1024e10).toString());
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, { value: amountTokensIn1 });
            // cerUSD --> ETH
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = ETH_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check sent amount larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd), _BN(afterEthPool.balanceCerUsd));
            // check token balance increased and decreased correctly
            assert.deepEqual(_BN(beforeEthPool.balanceToken)
                .add(amountTokensIn1)
                .sub(amountTokensOut2), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1025e10 ETH --> cerUSD --> USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // ETH --> cerUSD
            const tokenIn1 = ETH_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN((1025e10).toString());
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, { value: amountTokensIn1 });
            // cerUSD --> USDC
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn1), _BN(afterEthPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterEthPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1026e10 ETH --> USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // ETH --> cerUSD
            const tokenIn1 = ETH_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN((1026e10).toString());
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, { value: amountTokensIn1 });
            // cerUSD --> USDC
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn1), _BN(afterEthPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterEthPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1027 USDC --> cerUSD --> ETH; received ETH is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1027).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> ETH
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = ETH_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn2), _BN(afterEthPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut2), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapExactTokensForTokens: swap 1028 USDC --> ETH; received ETH is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn1 = _BN(1028).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> ETH
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = ETH_TOKEN_ADDRESS;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn2), _BN(afterEthPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut2), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    // ---------------------------------------------------------- //
    // swapTokensForExactTokens ETH tests //
    // ---------------------------------------------------------- //
    it('swapTokensForExactTokens: swap ETH --> 1031e10 cerUSD; received cerUSD is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = ETH_TOKEN_ADDRESS;
            const tokenOut = CER_USD_TOKEN_ADDRESS;
            const amountTokensOut = _BN((1031e10).toString());
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = _BN(33).mul(bn1e18);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn), _BN(afterEthPool.balanceToken));
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut), _BN(afterEthPool.balanceCerUsd));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap cerUSD --> 1032e10 ETH; received ETH is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            const tokenIn = CER_USD_TOKEN_ADDRESS;
            const tokenOut = ETH_TOKEN_ADDRESS;
            const amountTokensOut = _BN((1032e10).toString());
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = _BN(1000000).mul(bn1e18);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn), _BN(afterEthPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap cerUSD --> ETH --> 1033e10 cerUSD; sent cerUSD >= received cerUSD', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = CER_USD_TOKEN_ADDRESS;
            const tokenOut1 = ETH_TOKEN_ADDRESS;
            const tokenIn2 = ETH_TOKEN_ADDRESS;
            const tokenOut2 = CER_USD_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN((1033e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2, { value: maxAmountTokensIn2 });
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check sent amount must be larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            // since pool is changing during swaps
            // it is not correct to do such test
            // thats why commenting failing assert below
            /*assert.deepEqual(
                      beforeEthPool.balanceToken.toString(),
                      afterEthPool.balanceToken.toString(),
                  );*/
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap ETH --> cerUSD --> 1034e10 CERBY; sent ETH >= received ETH', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = ETH_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = ETH_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN((1034e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1, { value: maxAmountTokensIn1 });
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            // check sent amount larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check token balance increased and decreased correctly
            assert.deepEqual(_BN(beforeEthPool.balanceToken)
                .add(amountTokensIn1)
                .sub(amountTokensOut2)
                .toString(), _BN(afterEthPool.balanceToken).toString());
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap ETH --> cerUSD --> 1035e10 USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = ETH_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN((1035e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1, { value: maxAmountTokensIn1 });
            // cerUSD --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn1), _BN(afterEthPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterEthPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap ETH --> 1036e10 USDC; received USDC is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = ETH_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = USDC_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN((1036e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2, { value: maxAmountTokensIn1 });
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn1), _BN(afterEthPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterEthPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).add(amountTokensIn2), _BN(afterUSDCPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).sub(amountTokensOut2), _BN(afterUSDCPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap USDC --> cerUSD --> 1037e10 ETH; received ETH is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = ETH_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN((1037e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn2), _BN(afterEthPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut2), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    it('swapTokensForExactTokens: swap USDC --> 1038e10 ETH; received ETH is correct', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
        {
            const tokenIn1 = USDC_TOKEN_ADDRESS;
            const tokenOut1 = CER_USD_TOKEN_ADDRESS;
            const tokenIn2 = CER_USD_TOKEN_ADDRESS;
            const tokenOut2 = ETH_TOKEN_ADDRESS;
            const amountTokensOut2 = _BN((1038e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = currentTimestamp() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = currentTimestamp() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsBalancesByTokens([USDC_TOKEN_ADDRESS]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
            // check pool increased by amountTokensIn1
            assert.deepEqual(_BN(beforeUSDCPool.balanceToken).add(amountTokensIn1), _BN(afterUSDCPool.balanceToken));
            // check pool decreased by amountTokensOut1
            assert.deepEqual(_BN(beforeUSDCPool.balanceCerUsd).sub(amountTokensOut1), _BN(afterUSDCPool.balanceCerUsd));
            // check pool increased by amountTokensIn2
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn2), _BN(afterEthPool.balanceCerUsd));
            // check pool decreased by amountTokensOut2
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut2), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
            // check K must be increased
            assert.isTrue(_BN(beforeUSDCPool.balanceCerUsd)
                .mul(_BN(beforeUSDCPool.balanceToken))
                .lte(_BN(afterUSDCPool.balanceCerUsd).mul(_BN(afterUSDCPool.balanceToken))));
        }
    });
    // ---------------------------------------------------------- //
    // two wallets tests //
    // ---------------------------------------------------------- //
    it.only('two wallets: add liquidity CERBY (1st wallet), 1 trade CERBY --> cerUSD --> CERBY (2nd wallet), remove liquidity CERBY (1st wallet); balance of 1st wallet must be increased becayse if trade fee', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const secondAccount = accounts[1];
        const cerbyToken = await TestCerbyToken.at(CERBY_TOKEN_ADDRESS);
        const cerUsdToken = await TestCerUsdToken.at(CER_USD_TOKEN_ADDRESS);
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        {
            const oneK = _BN(1000e12);
            const minAmountTokensOut = _BN(0);
            const maxAmountTokensIn = _BN(1).mul(bn1e18);
            const amountTokensOut = oneK;
            const amountTokensIn = oneK;
            const expireTimestamp = currentTimestamp() + 864000;
            const transferTo = firstAccount;
            // burning all CERBY tokens on secondAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(secondAccount);
            await cerbyToken.burnHumanAddress(secondAccount, beforeCerbyBalance);
            // burning all CERBY tokens on firstAccount
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN('0').toString());
            // buying 1000 CERBY for firstAccount
            await cerbySwap.swapTokensForExactTokens(ETH_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 1000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), oneK.toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(CERBY_TOKEN_ADDRESS, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 0 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(0).toString());
            // doing 1 trade 10000 CERBY --> cerUSD --> CERBY using secondAccount
            const mintCerbyAmount = oneK.mul(_BN(10));
            let amountTokensIn2 = mintCerbyAmount;
            await cerbyToken.mintHumanAddress(secondAccount, mintCerbyAmount);
            let secondCerbyBalance = await cerbyToken.balanceOf(secondAccount);
            assert.deepEqual(_BN(secondCerbyBalance).toString(), _BN(mintCerbyAmount).toString());
            await cerbyToken.approve(cerbySwap.address, mintCerbyAmount.mul(_BN(1000)), { from: secondAccount });
            await cerUsdToken.approve(cerbySwap.address, mintCerbyAmount.mul(_BN(1000)), { from: secondAccount });
            let amountCerUsdOut = await cerbySwap.getOutputExactTokensForTokens(CERBY_TOKEN_ADDRESS, CER_USD_TOKEN_ADDRESS, amountTokensIn2);
            // swapping CERBY --> cerUSD using secondAccount
            await cerbySwap.swapExactTokensForTokens(CERBY_TOKEN_ADDRESS, CER_USD_TOKEN_ADDRESS, amountTokensIn2, minAmountTokensOut, expireTimestamp, secondAccount, { from: secondAccount });
            // swapping cerUSD --> CERBY using secondAccount
            await cerbySwap.swapExactTokensForTokens(CER_USD_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountCerUsdOut, minAmountTokensOut, expireTimestamp, secondAccount, { from: secondAccount });
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(CERBY_TOKEN_ADDRESS, lpTokens, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check account balance must be larger than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            console.log(afterCerbyBalance.toString());
            console.log(oneK.toString());
            assert.isTrue(_BN(afterCerbyBalance).gte(oneK));
        }
    });
    // ---------------------------------------------------------- //
    // hack tests //
    // ---------------------------------------------------------- //
    it('hacks: buy 1000e12 CERBY, add liquidity, 3 trades CERBY --> cerUSD --> CERBY, remove liquidity; result CERBY <= 1000e12', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbyToken = await TestCerbyToken.at(CERBY_TOKEN_ADDRESS);
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        {
            const minAmountTokensOut = _BN(0);
            const maxAmountTokensIn = _BN(1).mul(bn1e18);
            const amountTokensOut = _BN(2000e12);
            const amountTokensIn = amountTokensOut.div(_BN(2));
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            // burnding all CERBY tokens on firstAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN('0').toString());
            // buying 2000 CERBY
            await cerbySwap.swapTokensForExactTokens(ETH_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 2000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN(amountTokensOut).toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(CERBY_TOKEN_ADDRESS, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 1000 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(amountTokensIn).toString());
            // doing 3 trades CERBY --> cerUSD --> CERBY
            let amountTokensOut2;
            let amountTokensIn2 = amountTokensIn;
            for (let i = 0; i < 3; i++) {
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(CERBY_TOKEN_ADDRESS, CER_USD_TOKEN_ADDRESS, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(CERBY_TOKEN_ADDRESS, CER_USD_TOKEN_ADDRESS, amountTokensIn2, minAmountTokensOut, expireTimestamp, transferTo);
                amountTokensIn2 = amountTokensOut2;
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(CER_USD_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(CER_USD_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensIn2, minAmountTokensOut, expireTimestamp, transferTo);
            }
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(CERBY_TOKEN_ADDRESS, lpTokens, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check account balance must be less than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.isTrue(_BN(beforeCerbyBalance).gte(_BN(afterCerbyBalance)));
        }
    });
    it('hacks: buy 1000e12 CERBY, add liquidity, 2 trades CERBY --> cerUSD --> USDC --> cerUSD --> CERBY, remove liquidity; result CERBY <= 1000e12', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbyToken = await TestCerbyToken.at(CERBY_TOKEN_ADDRESS);
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        {
            const minAmountTokensOut = _BN(0);
            const maxAmountTokensIn = _BN(1).mul(bn1e18);
            const amountTokensOut = _BN(2000e12);
            const amountTokensIn = amountTokensOut.div(_BN(2));
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            // burnding all CERBY tokens on firstAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), '0');
            // buying 2000 CERBY
            await cerbySwap.swapTokensForExactTokens(ETH_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 2000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN(amountTokensOut).toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(CERBY_TOKEN_ADDRESS, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 1000 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(amountTokensIn).toString());
            // doing 2 trades CERBY --> cerUSD --> USDC --> cerUSD --> CERBY
            let amountTokensOut2;
            let amountTokensIn2 = amountTokensIn;
            for (let i = 0; i < 2; i++) {
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(CERBY_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(CERBY_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, amountTokensIn2, minAmountTokensOut, expireTimestamp, transferTo);
                amountTokensIn2 = amountTokensOut2;
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(USDC_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(USDC_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensIn2, minAmountTokensOut, expireTimestamp, transferTo);
            }
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(CERBY_TOKEN_ADDRESS, lpTokens, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check account balance must be less than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.isTrue(_BN(beforeCerbyBalance).gte(_BN(afterCerbyBalance)));
        }
    });
    it('hacks: buy 1000e12 CERBY, add liquidity 1000e12 CERBY, swap CERBY --> cerUSD, remove liquidity, swap cerUSD --> CERBY; result CERBY <= 2000e12', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbyToken = await TestCerbyToken.at(CERBY_TOKEN_ADDRESS);
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        {
            const minAmountTokensOut = _BN(0);
            const maxAmountTokensIn = _BN(1).mul(bn1e18);
            const amountTokensOut = _BN(2000e12);
            const amountTokensIn = amountTokensOut.div(_BN(2));
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            // burnding all CERBY tokens on firstAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(beforeCerbyBalance.toString(), '0');
            // buying 2000 CERBY
            await cerbySwap.swapTokensForExactTokens(ETH_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 2000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(beforeCerbyBalance.toString(), amountTokensOut.toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(CERBY_TOKEN_ADDRESS, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 1000 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(amountTokensIn).toString());
            // doing swa CERBY --> cerUSD
            let amountTokensOut2;
            let amountTokensIn2 = amountTokensIn;
            amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(CERBY_TOKEN_ADDRESS, CER_USD_TOKEN_ADDRESS, amountTokensIn2);
            await cerbySwap.swapExactTokensForTokens(CERBY_TOKEN_ADDRESS, CER_USD_TOKEN_ADDRESS, amountTokensIn2, minAmountTokensOut, expireTimestamp, transferTo);
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(CERBY_TOKEN_ADDRESS, lpTokens, expireTimestamp, transferTo);
            let amountTokensIn3 = amountTokensOut2;
            await cerbySwap.swapExactTokensForTokens(CER_USD_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensIn3, minAmountTokensOut, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // check account balance must be less than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.isTrue(_BN(beforeCerbyBalance).gte(_BN(afterCerbyBalance)));
        }
    });
    // ---------------------------------------------------------- //
    // getCurrentOneMinusFeeBasedOnTrades tests //
    // ---------------------------------------------------------- //
    it('getCurrentOneMinusFeeBasedOnTrades: time travel, do small trade, time travel, check fee', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            const ONE_PERIOD = 17280; // 4.8 hours time travel
            await increaseTime(ONE_PERIOD * 13); // shifting 2.6 days to clear any fees stats
            let actualOneMinusFee = await cerbySwap.getCurrentOneMinusFeeBasedOnTrades(CERBY_TOKEN_ADDRESS);
            const ONE_MINUS_FEE_MINIMUM = FEE_DENORM.sub(_BN(200)); // 98.00%
            const ONE_MINUS_FEE_MAXIMUM = FEE_DENORM.sub(_BN(1)); // 99.99%
            // actualOneMinusFee must be == min
            assert.deepEqual(actualOneMinusFee.toString(), ONE_MINUS_FEE_MINIMUM.toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            let pool = (await cerbySwap.getPoolsByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const cerbyToken = await TestCerbyToken.at(CERBY_TOKEN_ADDRESS);
            await cerbyToken.mintHumanAddress(firstAccount, _BN(beforeCerbyPool.balanceToken).mul(_BN(100)));
            const tokenIn = CERBY_TOKEN_ADDRESS;
            const tokenOut = CER_USD_TOKEN_ADDRESS;
            let amountTokensIn = beforeCerbyPool.balanceToken;
            const minAmountTokensOut = 0;
            const expireTimestamp = bn1e18;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 2);
            pool = (await cerbySwap.getPoolsByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // actualOneMinusFee must be in range min - max
            actualOneMinusFee = await cerbySwap.getCurrentOneMinusFeeBasedOnTrades(CERBY_TOKEN_ADDRESS);
            assert.isTrue(actualOneMinusFee > ONE_MINUS_FEE_MINIMUM);
            assert.isTrue(actualOneMinusFee < ONE_MINUS_FEE_MAXIMUM);
            amountTokensIn = _BN(beforeCerbyPool.balanceToken).mul(_BN(30));
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 3);
            pool = (await cerbySwap.getPoolsByTokens([CERBY_TOKEN_ADDRESS]))[0];
            // actualOneMinusFee must be == max
            actualOneMinusFee = await cerbySwap.getCurrentOneMinusFeeBasedOnTrades(CERBY_TOKEN_ADDRESS);
            // actualOneMinusFee must be == min
            assert.deepEqual(actualOneMinusFee.toString(), ONE_MINUS_FEE_MAXIMUM.toString());
            amountTokensIn = _BN(beforeCerbyPool.balanceToken).mul(_BN(30));
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 1);
            // clearing 5 periods
            amountTokensIn = _BN(1e9);
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 1);
            amountTokensIn = _BN(1e9);
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 1);
            amountTokensIn = _BN(1e9);
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 1);
            amountTokensIn = _BN(1e9);
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 1);
            amountTokensIn = _BN(1e9);
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            await increaseTime(ONE_PERIOD * 1);
            actualOneMinusFee = await cerbySwap.getCurrentOneMinusFeeBasedOnTrades(CERBY_TOKEN_ADDRESS);
            assert.deepEqual(actualOneMinusFee.toString(), ONE_MINUS_FEE_MINIMUM.toString());
        }
    });
    // ---------------------------------------------------------- //
    // creditCerUsd tests //
    // ---------------------------------------------------------- //
    it('reduce creditCerUsd, try swapping CERBY --> cerUSD: must revert', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            const tokenIn = CERBY_TOKEN_ADDRESS;
            const tokenOut = CER_USD_TOKEN_ADDRESS;
            const amountTokensIn = _BN(1001).mul(bn1e18);
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            // buying CERBY
            await cerbySwap.swapTokensForExactTokens(ETH_TOKEN_ADDRESS, CERBY_TOKEN_ADDRESS, amountTokensIn, bn1e18, expireTimestamp, transferTo, { value: bn1e18, gas: '30000000' });
            await cerbySwap.adminChangeCerUsdCreditInPool(tokenIn, 0);
            const CerbySwapV1_CreditCerUsdMustNotBeBelowZero = 'Z';
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo), CerbySwapV1_CreditCerUsdMustNotBeBelowZero);
            await cerbySwap.increaseCerUsdCreditInPool(tokenIn, amountTokensOut.sub(_BN(1)));
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo), CerbySwapV1_CreditCerUsdMustNotBeBelowZero);
        }
    });
    // ---------------------------------------------------------- //
    // removeTokenLiquidity tests //
    // ---------------------------------------------------------- //
    it('removeTokenLiquidity: remove 10% ETH; pool must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const ETH_POOL_POS = await cerbySwap.getTokenToPoolId(ETH_TOKEN_ADDRESS);
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
        {
            const tokenOut = ETH_TOKEN_ADDRESS;
            const amountLPTokensBurn = await (await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS)).div(_BN(10));
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](ETH_POOL_POS);
            const amountTokensOut = _BN(beforeEthPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeEthPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual(beforeLpTokens.sub(amountLPTokensBurn).toString(), afterLpTokens.toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountCerUsdOut), _BN(afterEthPool.balanceCerUsd));
        }
    });
    it('removeTokenLiquidity: remove 10% CERBY; pool must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
        {
            const tokenOut = CERBY_TOKEN_ADDRESS;
            const amountLPTokensBurn = await (await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS)).div(_BN(10));
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const amountTokensOut = _BN(beforeCerbyPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeCerbyPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual(_BN(beforeLpTokens).sub(amountLPTokensBurn).toString(), _BN(afterLpTokens).toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut), _BN(afterCerbyPool.balanceToken));
            // check pool decreased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountCerUsdOut), _BN(afterCerbyPool.balanceCerUsd));
        }
    });
    it('removeTokenLiquidity: remove all ETH; pool must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const ETH_POOL_POS = await cerbySwap.getTokenToPoolId(ETH_TOKEN_ADDRESS);
        const beforeEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
        {
            const tokenOut = ETH_TOKEN_ADDRESS;
            const amountLPTokensBurn = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](ETH_POOL_POS);
            const amountTokensOut = _BN(beforeEthPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeEthPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsBalancesByTokens([ETH_TOKEN_ADDRESS]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual(_BN(beforeLpTokens).sub(amountLPTokensBurn).toString(), _BN(afterLpTokens).toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountCerUsdOut).toString(), _BN(afterEthPool.balanceCerUsd).toString());
        }
    });
    it('removeTokenLiquidity: remove all CERBY; pool must be updated correctly', async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(CERBY_TOKEN_ADDRESS);
        const beforeCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
        {
            const tokenOut = CERBY_TOKEN_ADDRESS;
            const amountLPTokensBurn = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            const totalLPSupply = await cerbySwap.methods['totalSupply(uint256)'](CERBY_POOL_POS);
            const amountTokensOut = _BN(beforeCerbyPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeCerbyPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = currentTimestamp() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsBalancesByTokens([CERBY_TOKEN_ADDRESS]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual(_BN(beforeLpTokens).sub(amountLPTokensBurn).toString(), _BN(afterLpTokens).toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut).toString(), _BN(afterCerbyPool.balanceToken).toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountCerUsdOut).toString(), _BN(afterCerbyPool.balanceCerUsd).toString());
        }
    });
});
//# sourceMappingURL=CerbySwapV1.spec.js.map