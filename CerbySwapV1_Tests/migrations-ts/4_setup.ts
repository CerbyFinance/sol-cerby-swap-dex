import BN from "bn.js";

const CerbySwapV1 = artifacts.require("CerbySwapV1");

// const Weth = artifacts.require("WETH9");
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestCerUsdToken = artifacts.require("TestCerUsdToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");
const CerbyBotDetection = artifacts.require("CerbyBotDetection");

// const CerbySwapLP1155V1 = artifacts.require("CerbySwapLP1155V1");

const zeroAddr = "0x0000000000000000000000000000000000000000";

module.exports = async function (deployer) {
  const setup = async () => {
    const cerbySwap = await CerbySwapV1.deployed();

    await cerbySwap.testSetupTokens(
      zeroAddr,
      TestCerbyToken.address,

      TestCerUsdToken.address,
      TestUsdcToken.address,
      zeroAddr
      // Weth.address,
    );

    await cerbySwap.adminInitialize({ value: new BN((1e16).toString()) });
  };

  await setup();
} as Truffle.Migration;

export {};
