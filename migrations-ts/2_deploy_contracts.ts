
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestCerUsdToken = artifacts.require("TestCerUsdToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");
const VaultContract = artifacts.require("CerbySwapV1_Vault");

module.exports = function (deployer) {
  [
    TestCerbyToken,
    TestCerUsdToken,
    TestUsdcToken,
    VaultContract
  ].forEach((item) => deployer.deploy(item));

} as Truffle.Migration;

export {};
