"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const TestCerbyToken = artifacts.require("TestCerbyToken");
const TestCerUsdToken = artifacts.require("TestCerUsdToken");
const TestUsdcToken = artifacts.require("TestUsdcToken");
module.exports = function (deployer) {
    [
        TestCerbyToken,
        TestCerUsdToken,
        TestUsdcToken,
    ].forEach((item) => deployer.deploy(item));
};
//# sourceMappingURL=2_deploy_contracts.js.map