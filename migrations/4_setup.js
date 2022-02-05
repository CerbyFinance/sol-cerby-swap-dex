"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bn_js_1 = __importDefault(require("bn.js"));
const CerbySwapV1 = artifacts.require("CerbySwapV1");
// const Weth = artifacts.require("WETH9");
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestCerUsdToken = artifacts.require("TestCerUsdToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");
// const CerbyBotDetection = artifacts.require("CerbyBotDetection");
// const CerbySwapLP1155V1 = artifacts.require("CerbySwapLP1155V1");
const zeroAddr = "0x0000000000000000000000000000000000000000";
module.exports = async function (deployer) {
    const setup = async () => {
        const cerbySwap = await CerbySwapV1.deployed();
        await cerbySwap.testSetupTokens(zeroAddr, TestCerbyToken.address, TestCerUsdToken.address, TestUsdcToken.address, zeroAddr
        // Weth.address,
        );
        await cerbySwap.adminInitialize({ value: new bn_js_1.default((1e16).toString()) });
    };
    await setup();
};
//# sourceMappingURL=4_setup.js.map