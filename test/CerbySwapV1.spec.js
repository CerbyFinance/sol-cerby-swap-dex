"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bn_js_1 = __importDefault(require("bn.js"));
const crypto_1 = __importDefault(require("crypto"));
const truffleAssert = require("truffle-assertions");
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestCerUsdToken = artifacts.require("TestCerUsdToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");
const CerbySwapV1 = artifacts.require("CerbySwapV1");
// const CerbyBotDetection = artifacts.require("CerbyBotDetection");
const FEE_DENORM = 10000;
const DELAY_BETWEEN_TESTS = 0;
const now = () => Math.floor(+new Date() / 1000);
const randomAddress = () => "0x" + crypto_1.default.randomBytes(20).toString("hex");
const bn1e18 = new bn_js_1.default((1e18).toString());
const _BN = (value) => {
    return new bn_js_1.default(value);
};
function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
contract("Cerby", (accounts) => {
    // ---------------------------------------------------------- //
    // addTokenLiquidity tests //
    // ---------------------------------------------------------- //
    it.only("addTokenLiquidity: add 1041e10 ETH; pool must be updated correctly", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const [firstAccount, alice, bob, random] = accounts;
        const cerbySwap = await CerbySwapV1.deployed();
        const ETH_POOL_POS = await cerbySwap.getTokenToPoolId("0x14769F96e57B80c66837701DE0B43686Fb4632De");
        console.log(new Date().toUTCString());
        console.log("CerbySwapV1 Address: " + cerbySwap.address);
        console.log("TestCerbyToken Address: " + TestCerbyToken.address);
        console.log("TestCerUsdToken Address: " + TestCerUsdToken.address);
        console.log("TestUsdcToken Address: " + TestUsdcToken.address);
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
        {
            const tokenIn = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensIn = _BN(1041e10);
            const amountCerUsdIn = amountTokensIn
                .mul(_BN(beforeEthPool.balanceCerUsd))
                .div(_BN(beforeEthPool.balanceToken));
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](ETH_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeEthPool.balanceToken));
            await cerbySwap.addTokenLiquidity(tokenIn, amountTokensIn, expireTimestamp, transferTo, { value: amountTokensIn, gas: "300000" });
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            // check lp tokens increased
            assert.deepEqual(beforeLpTokens.add(lpTokens).toString(), afterLpTokens.toString());
            // check pool increased balance
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn), _BN(afterEthPool.balanceToken));
            // check pool increased balance
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountCerUsdIn), _BN(afterEthPool.balanceCerUsd));
        }
    });
    it.only("addTokenLiquidity: add 1042 CERBY; pool must be updated correctly", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(TestCerbyToken.address);
        const res = await cerbySwap.getPoolsByTokens([TestCerbyToken.address]);
        const beforeCerbyPool = res[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
        {
            const tokenIn = TestCerbyToken.address;
            const amountTokensIn = _BN(1042).mul(bn1e18);
            const amountCerUsdIn = amountTokensIn
                .mul(_BN(beforeCerbyPool.balanceCerUsd))
                .div(_BN(beforeCerbyPool.balanceToken));
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(tokenIn, amountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1001 CERBY --> cerUSD; received cerUSD is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const tokenIn = TestCerbyToken.address;
        const tokenOut = TestCerUsdToken.address;
        const amountTokensIn = _BN(1001).mul(bn1e18);
        const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, {
            gas: "3000000"
        });
        const minAmountTokensOut = 0;
        const expireTimestamp = now() + 86400;
        const transferTo = firstAccount;
        await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo, {
            gas: "3000000"
        });
        const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        // check pool increased by amountTokensIn
        assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn), _BN(afterCerbyPool.balanceToken));
        assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut), _BN(afterCerbyPool.balanceCerUsd));
        // check K must be increased
        assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
            .mul(_BN(beforeCerbyPool.balanceToken))
            .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
    });
    it.only("swapExactTokensForTokens: swap 1002 cerUSD --> CERBY; received CERBY is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            const tokenIn = TestCerUsdToken.address;
            const tokenOut = TestCerbyToken.address;
            const amountTokensIn = _BN(1002).mul(bn1e18);
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo, {
                gas: "3000000"
            });
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn), _BN(afterCerbyPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it.only("swapExactTokensForTokens: swap 1003 cerUSD --> CERBY --> cerUSD; sent cerUSD >= received cerUSD", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            // cerUSD --> CERBY
            const tokenIn1 = TestCerUsdToken.address;
            const tokenOut1 = TestCerbyToken.address;
            const amountTokensIn1 = _BN(1003).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // CERBY --> cerUSD
            const tokenIn2 = TestCerbyToken.address;
            const tokenOut2 = TestCerUsdToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1004 CERBY --> cerUSD --> CERBY; sent CERBY >= received CERBY", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            // CERBY --> cerUSD
            const tokenIn1 = TestCerbyToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = _BN(1004).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestCerbyToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1005 CERBY --> cerUSD --> USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // CERBY --> cerUSD
            const tokenIn1 = TestCerbyToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = _BN(1005).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> USDC
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1006 CERBY --> USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // CERBY --> cerUSD
            const tokenIn1 = TestCerbyToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = _BN(1006).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> USDC
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1007 USDC --> cerUSD --> CERBY; received CERBY is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = _BN(1007).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestCerbyToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1008 USDC --> CERBY; received CERBY is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = _BN(1008).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> CERBY
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestCerbyToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: check reverts", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            // cerUSD --> cerUSD
            const SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L = "L";
            let tokenIn1 = TestCerUsdToken.address;
            let tokenOut1 = TestCerUsdToken.address;
            let amountTokensIn1 = _BN(1010).mul(bn1e18);
            let minAmountTokensOut1 = _BN(0);
            let expireTimestamp1 = now() + 86400;
            let transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L);
            // CERBY --> CERBY
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(1000000000).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L);
            const OUTPUT_CERUSD_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_H = "H";
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerUsdToken.address;
            amountTokensIn1 = _BN(1010).mul(bn1e18);
            minAmountTokensOut1 = _BN(1000000000).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), OUTPUT_CERUSD_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_H);
            const OUTPUT_TOKENS_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_i = "i";
            tokenIn1 = TestCerUsdToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensIn1 = new bn_js_1.default(1010).mul(bn1e18);
            minAmountTokensOut1 = new bn_js_1.default(1000000000).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, {
                gas: 6700000,
            }), OUTPUT_TOKENS_AMOUNT_IS_LESS_THAN_MINIMUM_SPECIFIED_i);
            const TRANSACTION_IS_EXPIRED_D = "D";
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerUsdToken.address;
            amountTokensIn1 = new bn_js_1.default(1010).mul(bn1e18);
            minAmountTokensOut1 = new bn_js_1.default(0);
            expireTimestamp1 = now() - 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), TRANSACTION_IS_EXPIRED_D);
            const AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F = "F";
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerUsdToken.address;
            amountTokensIn1 = new bn_js_1.default(0).mul(bn1e18);
            minAmountTokensOut1 = new bn_js_1.default(0);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            tokenIn1 = TestCerUsdToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensIn1 = new bn_js_1.default(0).mul(bn1e18);
            minAmountTokensOut1 = new bn_js_1.default(0);
            amountTokensIn1 = new bn_js_1.default(0);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            tokenIn1 = TestUsdcToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensIn1 = new bn_js_1.default(0).mul(bn1e18);
            minAmountTokensOut1 = new bn_js_1.default(0);
            amountTokensIn1 = new bn_js_1.default(0);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
        }
    });
    // ---------------------------------------------------------- //
    // swapTokensForExactTokens tests //
    // ---------------------------------------------------------- //
    it.only("swapTokensForExactTokens: swap CERBY --> 1011 cerUSD; received cerUSD is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            const tokenIn = TestCerbyToken.address;
            const tokenOut = TestCerUsdToken.address;
            const amountTokensOut = new bn_js_1.default(1011).mul(bn1e18);
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).add(amountTokensIn), _BN(afterCerbyPool.balanceToken));
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountTokensOut), _BN(afterCerbyPool.balanceCerUsd));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it.only("swapTokensForExactTokens: swap cerUSD --> 1012 CERBY; received CERBY is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            const tokenIn = TestCerUsdToken.address;
            const tokenOut = TestCerbyToken.address;
            const amountTokensOut = new bn_js_1.default(1012).mul(bn1e18);
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).add(amountTokensIn), _BN(afterCerbyPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut), _BN(afterCerbyPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeCerbyPool.balanceCerUsd)
                .mul(_BN(beforeCerbyPool.balanceToken))
                .lte(_BN(afterCerbyPool.balanceCerUsd).mul(_BN(afterCerbyPool.balanceToken))));
        }
    });
    it.only("swapTokensForExactTokens: swap cerUSD --> CERBY --> 1013 cerUSD; sent cerUSD >= received cerUSD", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            const tokenIn1 = TestCerUsdToken.address;
            const tokenOut1 = TestCerbyToken.address;
            const tokenIn2 = TestCerbyToken.address;
            const tokenOut2 = TestCerUsdToken.address;
            const amountTokensOut2 = new bn_js_1.default(1013).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
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
    it.only("swapTokensForExactTokens: swap CERBY --> cerUSD --> 1014 CERBY; sent CERBY >= received CERBY", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        {
            const tokenIn1 = TestCerbyToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestCerbyToken.address;
            const amountTokensOut2 = _BN(1014).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = _BN(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = _BN(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
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
    it.only("swapTokensForExactTokens: swap CERBY --> cerUSD --> 1015 USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = TestCerbyToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensOut2 = new bn_js_1.default(1015).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd)
                .add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
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
    it.only("swapTokensForExactTokens: swap CERBY --> 1016 USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = TestCerbyToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensOut2 = new bn_js_1.default(1016).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapTokensForExactTokens: swap USDC --> cerUSD --> 1017 CERBY; received CERBY is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestCerbyToken.address;
            const amountTokensOut2 = new bn_js_1.default(1017).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd)
                .add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
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
    it.only("swapTokensForExactTokens: swap USDC --> 1018 CERBY; received CERBY is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestCerbyToken.address;
            const amountTokensOut2 = new bn_js_1.default(1018).mul(bn1e18);
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd)
                .add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterCerbyPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
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
    it.only("swapTokensForExactTokens: check reverts", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            // cerUSD --> cerUSD
            const SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L = "L";
            let tokenIn1 = TestCerUsdToken.address;
            let tokenOut1 = TestCerUsdToken.address;
            let amountTokensOut1 = new bn_js_1.default(1020).mul(bn1e18);
            let maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            let expireTimestamp1 = now() + 86400;
            let transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), SWAP_CERUSD_FOR_CERUSD_IS_FORBIDDEN_L);
            const OUTPUT_TOKENS_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_K = "K";
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerUsdToken.address;
            amountTokensOut1 = new bn_js_1.default(1020).mul(bn1e18);
            maxAmountTokensIn1 = new bn_js_1.default(0).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), OUTPUT_TOKENS_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_K);
            const OUTPUT_CERUSD_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_J = "J";
            tokenIn1 = TestCerUsdToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensOut1 = new bn_js_1.default(1020).mul(bn1e18);
            maxAmountTokensIn1 = new bn_js_1.default(0).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), OUTPUT_CERUSD_AMOUNT_IS_MORE_THAN_MAXIMUM_SPECIFIED_J);
            const TRANSACTION_IS_EXPIRED_D = "D";
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerUsdToken.address;
            amountTokensOut1 = new bn_js_1.default(1020).mul(bn1e18);
            maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            expireTimestamp1 = now() - 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), TRANSACTION_IS_EXPIRED_D);
            const AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F = "F";
            tokenIn1 = TestCerbyToken.address;
            tokenOut1 = TestCerUsdToken.address;
            amountTokensOut1 = new bn_js_1.default(0);
            maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), AMOUNT_OF_TOKENS_MUST_BE_LARGER_THAN_ZERO_F);
            const AMOUNT_OF_CERUSD_MUST_BE_LARGER_THAN_ZERO_U = "U";
            tokenIn1 = TestCerUsdToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensOut1 = new bn_js_1.default(0);
            maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), AMOUNT_OF_CERUSD_MUST_BE_LARGER_THAN_ZERO_U);
            tokenIn1 = TestUsdcToken.address;
            tokenOut1 = TestCerbyToken.address;
            amountTokensOut1 = new bn_js_1.default(0);
            maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            expireTimestamp1 = now() + 86400;
            transferTo1 = firstAccount;
            await truffleAssert.reverts(cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1), AMOUNT_OF_CERUSD_MUST_BE_LARGER_THAN_ZERO_U);
        }
    });
    // ---------------------------------------------------------- //
    // swapExactTokensForTokens ETH tests //
    // ---------------------------------------------------------- //
    it.only("swapExactTokensForTokens: swap 1021e10 ETH --> cerUSD; received cerUSD is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            const tokenIn = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut = TestCerUsdToken.address;
            const amountTokensIn = new bn_js_1.default((1021e10).toString());
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo, { value: amountTokensIn });
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn), _BN(afterEthPool.balanceToken));
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut), _BN(afterEthPool.balanceCerUsd));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it.only("swapExactTokensForTokens: swap 1022 cerUSD --> ETH; received ETH is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            const tokenIn = TestCerUsdToken.address;
            const tokenOut = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensIn = new bn_js_1.default(1022).mul(bn1e18);
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn), _BN(afterEthPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it.only("swapExactTokensForTokens: swap 1023 cerUSD --> ETH --> cerUSD; sent cerUSD >= received cerUSD", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            // cerUSD --> ETH
            const tokenIn1 = TestCerUsdToken.address;
            const tokenOut1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensIn1 = new bn_js_1.default(1023).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // ETH --> cerUSD
            const tokenIn2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut2 = TestCerUsdToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2, { value: amountTokensIn2 });
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
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
    it.only("swapExactTokensForTokens: swap 1024e10 ETH --> cerUSD --> ETH; sent ETH >= received ETH", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            // ETH --> cerUSD
            const tokenIn1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = new bn_js_1.default((1024e10).toString());
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, { value: amountTokensIn1 });
            // cerUSD --> ETH
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
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
    it.only("swapExactTokensForTokens: swap 1025e10 ETH --> cerUSD --> USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // ETH --> cerUSD
            const tokenIn1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = new bn_js_1.default((1025e10).toString());
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, { value: amountTokensIn1 });
            // cerUSD --> USDC
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1026e10 ETH --> USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // ETH --> cerUSD
            const tokenIn1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = new bn_js_1.default((1026e10).toString());
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1, { value: amountTokensIn1 });
            // cerUSD --> USDC
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1027 USDC --> cerUSD --> ETH; received ETH is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = new bn_js_1.default(1027).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1, minAmountTokensOut1, expireTimestamp1, transferTo1);
            // cerUSD --> ETH
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapExactTokensForTokens: swap 1028 USDC --> ETH; received ETH is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            // USDC --> cerUSD
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const amountTokensIn1 = new bn_js_1.default(1028).mul(bn1e18);
            const amountTokensOut1 = await cerbySwap.getOutputExactTokensForTokens(tokenIn1, tokenOut1, amountTokensIn1);
            const minAmountTokensOut1 = 0;
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            // cerUSD --> ETH
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensIn2 = amountTokensOut1;
            const amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(tokenIn2, tokenOut2, amountTokensIn2);
            const minAmountTokensOut2 = 0;
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            await cerbySwap.swapExactTokensForTokens(tokenIn1, tokenOut2, amountTokensIn1, minAmountTokensOut2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
            // check sum cerUsd balances in USDC and Cerby pools must be equal
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd)
                .add(_BN(beforeUSDCPool.balanceCerUsd)), _BN(afterEthPool.balanceCerUsd).add(_BN(afterUSDCPool.balanceCerUsd)));
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
    it.only("swapTokensForExactTokens: swap ETH --> 1031e10 cerUSD; received cerUSD is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            const tokenIn = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut = TestCerUsdToken.address;
            const amountTokensOut = new bn_js_1.default((1031e10).toString());
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = new bn_js_1.default(33).mul(bn1e18);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceToken).add(amountTokensIn), _BN(afterEthPool.balanceToken));
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountTokensOut), _BN(afterEthPool.balanceCerUsd));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it.only("swapTokensForExactTokens: swap cerUSD --> 1032e10 ETH; received ETH is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            const tokenIn = TestCerUsdToken.address;
            const tokenOut = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensOut = new bn_js_1.default((1032e10).toString());
            const amountTokensIn = await cerbySwap.getInputTokensForExactTokens(tokenIn, tokenOut, amountTokensOut);
            const maxAmountTokensIn = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.swapTokensForExactTokens(tokenIn, tokenOut, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            // check pool increased by amountTokensIn
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).add(amountTokensIn), _BN(afterEthPool.balanceCerUsd));
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it.only("swapTokensForExactTokens: swap cerUSD --> ETH --> 1033e10 cerUSD; sent cerUSD >= received cerUSD", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            const tokenIn1 = TestCerUsdToken.address;
            const tokenOut1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenIn2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut2 = TestCerUsdToken.address;
            const amountTokensOut2 = new bn_js_1.default((1033e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2, { value: maxAmountTokensIn2 });
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
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
    it.only("swapTokensForExactTokens: swap ETH --> cerUSD --> 1034e10 CERBY; sent ETH >= received ETH", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        {
            const tokenIn1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensOut2 = new bn_js_1.default((1034e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1, { value: maxAmountTokensIn1 });
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            // check sent amount larger than received
            assert.isTrue(amountTokensIn1.gte(amountTokensOut2));
            // check intermediate token balance must not change
            // since pool is changing during swaps
            // it is not correct to do such test
            // thats why commenting failing assert below // Q: why not use notDeepEqual?
            /*assert.deepEqual(
                beforeEthPool.balanceCerUsd.toString(),
                afterEthPool.balanceCerUsd.toString(),
            );*/
            // check token balance increased and decreased correctly
            assert.deepEqual((_BN(beforeEthPool.balanceToken)
                .add(amountTokensIn1)
                .sub(amountTokensOut2)).toString(), (_BN(afterEthPool.balanceToken)).toString());
            // check K must be increased
            assert.isTrue(_BN(beforeEthPool.balanceCerUsd)
                .mul(_BN(beforeEthPool.balanceToken))
                .lte(_BN(afterEthPool.balanceCerUsd).mul(_BN(afterEthPool.balanceToken))));
        }
    });
    it.only("swapTokensForExactTokens: swap ETH --> cerUSD --> 1035e10 USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensOut2 = new bn_js_1.default((1035e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1, { value: maxAmountTokensIn1 });
            // cerUSD --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapTokensForExactTokens: swap ETH --> 1036e10 USDC; received USDC is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = TestUsdcToken.address;
            const amountTokensOut2 = new bn_js_1.default((1036e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // CERBY --> USDC
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2, { value: maxAmountTokensIn1 });
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapTokensForExactTokens: swap USDC --> cerUSD --> 1037e10 ETH; received ETH is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensOut2 = new bn_js_1.default((1037e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> cerUSD
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1, maxAmountTokensIn1, expireTimestamp1, transferTo1);
            // cerUSD --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    it.only("swapTokensForExactTokens: swap USDC --> 1038e10 ETH; received ETH is correct", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
        {
            const tokenIn1 = TestUsdcToken.address;
            const tokenOut1 = TestCerUsdToken.address;
            const tokenIn2 = TestCerUsdToken.address;
            const tokenOut2 = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountTokensOut2 = new bn_js_1.default((1038e10).toString());
            const amountTokensIn2 = await cerbySwap.getInputTokensForExactTokens(tokenIn2, tokenOut2, amountTokensOut2);
            const amountTokensOut1 = amountTokensIn2;
            const amountTokensIn1 = await cerbySwap.getInputTokensForExactTokens(tokenIn1, tokenOut1, amountTokensOut1);
            const maxAmountTokensIn1 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp1 = now() + 86400;
            const transferTo1 = firstAccount;
            const maxAmountTokensIn2 = new bn_js_1.default(1000000).mul(bn1e18);
            const expireTimestamp2 = now() + 86400;
            const transferTo2 = firstAccount;
            // USDC --> CERBY
            await cerbySwap.swapTokensForExactTokens(tokenIn1, tokenOut2, amountTokensOut2, maxAmountTokensIn2, expireTimestamp2, transferTo2);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterUSDCPool = (await cerbySwap.getPoolsByTokens([TestUsdcToken.address]))[0];
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
    // hack tests //
    // ---------------------------------------------------------- //
    it.only("hacks: buy 1000e12 CERBY, add liquidity, 3 trades CERBY --> cerUSD --> CERBY, remove liquidity; result CERBY <= 1000e12", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbyToken = await TestCerbyToken.deployed();
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(TestCerbyToken.address);
        {
            const minAmountTokensIn = new bn_js_1.default(0);
            const maxAmountTokensIn = new bn_js_1.default(1).mul(bn1e18);
            const amountTokensOut = new bn_js_1.default(2000e12);
            const amountTokensIn = amountTokensOut.div(new bn_js_1.default(2));
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            // burnding all CERBY tokens on firstAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN("0").toString());
            // buying 2000 CERBY
            await cerbySwap.swapTokensForExactTokens("0x14769F96e57B80c66837701DE0B43686Fb4632De", TestCerbyToken.address, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 2000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN(amountTokensOut).toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(TestCerbyToken.address, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 1000 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(amountTokensIn).toString());
            // doing 3 trades CERBY --> cerUSD --> CERBY
            let amountTokensOut2;
            let amountTokensIn2 = amountTokensIn;
            for (let i = 0; i < 3; i++) {
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(TestCerbyToken.address, TestCerUsdToken.address, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(TestCerbyToken.address, TestCerUsdToken.address, amountTokensIn2, minAmountTokensIn, expireTimestamp, transferTo);
                amountTokensIn2 = amountTokensOut2;
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(TestCerUsdToken.address, TestCerbyToken.address, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(TestCerUsdToken.address, TestCerbyToken.address, amountTokensIn2, minAmountTokensIn, expireTimestamp, transferTo);
            }
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(TestCerbyToken.address, lpTokens, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // check account balance must be less than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.isTrue(_BN(beforeCerbyBalance).gte(_BN(afterCerbyBalance)));
        }
    });
    it.only("hacks: buy 1000e12 CERBY, add liquidity, 2 trades CERBY --> cerUSD --> USDC --> cerUSD --> CERBY, remove liquidity; result CERBY <= 1000e12", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbyToken = await TestCerbyToken.deployed();
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(TestCerbyToken.address);
        {
            const minAmountTokensIn = new bn_js_1.default(0);
            const maxAmountTokensIn = new bn_js_1.default(1).mul(bn1e18);
            const amountTokensOut = new bn_js_1.default(2000e12);
            const amountTokensIn = amountTokensOut.div(new bn_js_1.default(2));
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            // burnding all CERBY tokens on firstAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), "0");
            // buying 2000 CERBY
            await cerbySwap.swapTokensForExactTokens("0x14769F96e57B80c66837701DE0B43686Fb4632De", TestCerbyToken.address, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 2000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(beforeCerbyBalance).toString(), _BN(amountTokensOut).toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(TestCerbyToken.address, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 1000 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(amountTokensIn).toString());
            // doing 2 trades CERBY --> cerUSD --> USDC --> cerUSD --> CERBY
            let amountTokensOut2;
            let amountTokensIn2 = amountTokensIn;
            for (let i = 0; i < 2; i++) {
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(TestCerbyToken.address, TestUsdcToken.address, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(TestCerbyToken.address, TestUsdcToken.address, amountTokensIn2, minAmountTokensIn, expireTimestamp, transferTo);
                amountTokensIn2 = amountTokensOut2;
                amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(TestUsdcToken.address, TestCerbyToken.address, amountTokensIn2);
                await cerbySwap.swapExactTokensForTokens(TestUsdcToken.address, TestCerbyToken.address, amountTokensIn2, minAmountTokensIn, expireTimestamp, transferTo);
            }
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(TestCerbyToken.address, lpTokens, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // check account balance must be less than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.isTrue(_BN(beforeCerbyBalance).gte(_BN(afterCerbyBalance)));
        }
    });
    it.only("hacks: buy 1000e12 CERBY, add liquidity 1000e12 CERBY, swap CERBY --> cerUSD, remove liquidity, swap cerUSD --> CERBY; result CERBY <= 2000e12", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbyToken = await TestCerbyToken.deployed();
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(TestCerbyToken.address);
        {
            const minAmountTokensIn = new bn_js_1.default(0);
            const maxAmountTokensIn = new bn_js_1.default(1).mul(bn1e18);
            const amountTokensOut = new bn_js_1.default(2000e12);
            const amountTokensIn = amountTokensOut.div(new bn_js_1.default(2));
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            // burnding all CERBY tokens on firstAccount
            let beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            await cerbyToken.burnHumanAddress(firstAccount, beforeCerbyBalance);
            // check account balance must be 0 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(beforeCerbyBalance.toString(), "0");
            // buying 2000 CERBY
            await cerbySwap.swapTokensForExactTokens("0x14769F96e57B80c66837701DE0B43686Fb4632De", TestCerbyToken.address, amountTokensOut, maxAmountTokensIn, expireTimestamp, transferTo, { value: maxAmountTokensIn });
            // check account balance must be 2000 CERBY
            beforeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(beforeCerbyBalance.toString(), amountTokensOut.toString());
            const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // adding 1000 CERBY to liquidity
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](CERBY_POOL_POS);
            const lpTokens = amountTokensIn
                .mul(totalLPSupply)
                .div(_BN(beforeCerbyPool.balanceToken));
            await cerbySwap.addTokenLiquidity(TestCerbyToken.address, amountTokensIn, expireTimestamp, transferTo);
            // check account balance must be 1000 CERBY
            let midtimeCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.deepEqual(_BN(midtimeCerbyBalance).toString(), _BN(amountTokensIn).toString());
            // doing swa CERBY --> cerUSD
            let amountTokensOut2;
            let amountTokensIn2 = amountTokensIn;
            amountTokensOut2 = await cerbySwap.getOutputExactTokensForTokens(TestCerbyToken.address, TestCerUsdToken.address, amountTokensIn2);
            await cerbySwap.swapExactTokensForTokens(TestCerbyToken.address, TestCerUsdToken.address, amountTokensIn2, minAmountTokensIn, expireTimestamp, transferTo);
            // removing liquidity
            await cerbySwap.removeTokenLiquidity(TestCerbyToken.address, lpTokens, expireTimestamp, transferTo);
            let amountTokensIn3 = amountTokensOut2;
            await cerbySwap.swapExactTokensForTokens(TestCerUsdToken.address, TestCerbyToken.address, amountTokensIn3, minAmountTokensIn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            // check account balance must be less than 1000 CERBY
            const afterCerbyBalance = await cerbyToken.balanceOf(firstAccount);
            assert.isTrue(_BN(beforeCerbyBalance).gte(_BN(afterCerbyBalance)));
        }
    });
    // ---------------------------------------------------------- //
    // creditCerUsd tests //
    // ---------------------------------------------------------- //
    it.only("reduce creditCerUsd, try swapping CERBY --> cerUSD: must revert", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        {
            const tokenIn = TestCerbyToken.address;
            const tokenOut = TestCerUsdToken.address;
            const amountTokensIn = new bn_js_1.default(1001).mul(bn1e18);
            const amountTokensOut = await cerbySwap.getOutputExactTokensForTokens(tokenIn, tokenOut, amountTokensIn);
            const minAmountTokensOut = 0;
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            // buying CERBY
            await cerbySwap.swapTokensForExactTokens("0x14769F96e57B80c66837701DE0B43686Fb4632De", TestCerbyToken.address, amountTokensIn, bn1e18, expireTimestamp, transferTo, { value: bn1e18 });
            await cerbySwap.adminChangeCerUsdCreditInPool(tokenIn, 0);
            const CerbySwapV1_CreditCerUsdMustNotBeBelowZero = "Z";
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo), CerbySwapV1_CreditCerUsdMustNotBeBelowZero);
            await cerbySwap.adminChangeCerUsdCreditInPool(tokenIn, amountTokensOut.sub(new bn_js_1.default(1)));
            await truffleAssert.reverts(cerbySwap.swapExactTokensForTokens(tokenIn, tokenOut, amountTokensIn, minAmountTokensOut, expireTimestamp, transferTo), CerbySwapV1_CreditCerUsdMustNotBeBelowZero);
        }
    });
    // ---------------------------------------------------------- //
    // removeTokenLiquidity tests //
    // ---------------------------------------------------------- //
    it.only("removeTokenLiquidity: remove 10% ETH; pool must be updated correctly", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const ETH_POOL_POS = await cerbySwap.getTokenToPoolId("0x14769F96e57B80c66837701DE0B43686Fb4632De");
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
        {
            const tokenOut = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountLPTokensBurn = await (await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS)).div(new bn_js_1.default(10));
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](ETH_POOL_POS);
            const amountTokensOut = _BN(beforeEthPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeEthPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual(beforeLpTokens.sub(amountLPTokensBurn).toString(), afterLpTokens.toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceCerUsd).sub(amountCerUsdOut), _BN(afterEthPool.balanceCerUsd));
        }
    });
    it.only("removeTokenLiquidity: remove 10% CERBY; pool must be updated correctly", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(TestCerbyToken.address);
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
        {
            const tokenOut = TestCerbyToken.address;
            const amountLPTokensBurn = await (await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS)).div(new bn_js_1.default(10));
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](CERBY_POOL_POS);
            const amountTokensOut = _BN(beforeCerbyPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeCerbyPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual((_BN(beforeLpTokens).sub(amountLPTokensBurn)).toString(), (_BN(afterLpTokens)).toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut), _BN(afterCerbyPool.balanceToken));
            // check pool decreased balance
            assert.deepEqual(_BN(beforeCerbyPool.balanceCerUsd).sub(amountCerUsdOut), _BN(afterCerbyPool.balanceCerUsd));
        }
    });
    it.only("removeTokenLiquidity: remove all ETH; pool must be updated correctly", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const ETH_POOL_POS = await cerbySwap.getTokenToPoolId("0x14769F96e57B80c66837701DE0B43686Fb4632De");
        const beforeEthPool = (await cerbySwap.getPoolsByTokens([
            "0x14769F96e57B80c66837701DE0B43686Fb4632De",
        ]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
        {
            const tokenOut = "0x14769F96e57B80c66837701DE0B43686Fb4632De";
            const amountLPTokensBurn = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](ETH_POOL_POS);
            const amountTokensOut = _BN(beforeEthPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeEthPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterEthPool = (await cerbySwap.getPoolsByTokens([
                "0x14769F96e57B80c66837701DE0B43686Fb4632De",
            ]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, ETH_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual((_BN(beforeLpTokens).sub(amountLPTokensBurn)).toString(), (_BN(afterLpTokens)).toString());
            // check pool decreased balance
            assert.deepEqual(_BN(beforeEthPool.balanceToken).sub(amountTokensOut), _BN(afterEthPool.balanceToken));
            // check pool decreased balance
            assert.deepEqual((_BN(beforeEthPool.balanceCerUsd).sub(amountCerUsdOut)).toString(), (_BN(afterEthPool.balanceCerUsd)).toString());
        }
    });
    it.only("removeTokenLiquidity: remove all CERBY; pool must be updated correctly", async () => {
        await delay(DELAY_BETWEEN_TESTS);
        const accounts = await web3.eth.getAccounts();
        const firstAccount = accounts[0];
        const cerbySwap = await CerbySwapV1.deployed();
        const CERBY_POOL_POS = await cerbySwap.getTokenToPoolId(TestCerbyToken.address);
        const beforeCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
        const beforeLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
        {
            const tokenOut = TestCerbyToken.address;
            const amountLPTokensBurn = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            const totalLPSupply = await cerbySwap.methods["totalSupply(uint256)"](CERBY_POOL_POS);
            const amountTokensOut = _BN(beforeCerbyPool.balanceToken)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const amountCerUsdOut = _BN(beforeCerbyPool.balanceCerUsd)
                .mul(amountLPTokensBurn)
                .div(totalLPSupply);
            const expireTimestamp = now() + 86400;
            const transferTo = firstAccount;
            await cerbySwap.removeTokenLiquidity(tokenOut, amountLPTokensBurn, expireTimestamp, transferTo);
            const afterCerbyPool = (await cerbySwap.getPoolsByTokens([TestCerbyToken.address]))[0];
            const afterLpTokens = await cerbySwap.balanceOf(firstAccount, CERBY_POOL_POS);
            // check lp tokens decreased
            assert.deepEqual((_BN(beforeLpTokens).sub(amountLPTokensBurn)).toString(), (_BN(afterLpTokens)).toString());
            // check pool decreased balance
            assert.deepEqual((_BN(beforeCerbyPool.balanceToken).sub(amountTokensOut)).toString(), (_BN(afterCerbyPool.balanceToken)).toString());
            // check pool decreased balance
            assert.deepEqual((_BN(beforeCerbyPool.balanceCerUsd).sub(amountCerUsdOut)).toString(), (_BN(afterCerbyPool.balanceCerUsd)).toString());
        }
    });
});
//# sourceMappingURL=CerbySwapV1.spec.js.map