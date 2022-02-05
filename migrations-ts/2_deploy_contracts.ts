
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestCerUsdToken = artifacts.require("TestCerUsdToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");

module.exports = function (deployer) {
  [
    TestCerbyToken,
    TestCerUsdToken,
    TestUsdcToken,
  ].forEach((item) => deployer.deploy(item));
} as Truffle.Migration;

export {};
