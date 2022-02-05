"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TestCerbyToken2 = void 0;
const TestCerbyToken = artifacts.require("TestCerbyToken");
let token;
const TestCerbyToken2 = async () => {
    if (!token) {
        token = await TestCerbyToken.new();
        return token;
    }
    return token;
};
exports.TestCerbyToken2 = TestCerbyToken2;
//# sourceMappingURL=utils.js.map