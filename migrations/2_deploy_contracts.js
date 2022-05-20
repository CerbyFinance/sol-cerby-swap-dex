"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestBtcToken = artifacts.require("TestBtcToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");
const VaultContract = artifacts.require("CerbySwapV1_Vault");
module.exports = function (deployer) {
    [
        TestCerbyToken,
        TestBtcToken,
        TestUsdcToken,
        VaultContract
    ].forEach((item) => deployer.deploy(item));
};
//# sourceMappingURL=2_deploy_contracts.js.map