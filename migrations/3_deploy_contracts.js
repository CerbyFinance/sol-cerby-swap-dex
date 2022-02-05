"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const CerbySwapV1 = artifacts.require("CerbySwapV1");
module.exports = function (deployer) {
    [CerbySwapV1].forEach((item) => deployer.deploy(item));
};
//# sourceMappingURL=3_deploy_contracts.js.map