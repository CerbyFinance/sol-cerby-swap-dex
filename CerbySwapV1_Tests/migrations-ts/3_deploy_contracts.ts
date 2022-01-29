const CerbySwapV1 = artifacts.require("CerbySwapV1");

module.exports = function (deployer) {
  [CerbySwapV1].forEach(item => deployer.deploy(item));
} as Truffle.Migration;

export {};
