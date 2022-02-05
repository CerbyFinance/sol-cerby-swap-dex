import { TestCerbyTokenInstance } from "../types/truffle-contracts";
const TestCerbyToken = artifacts.require("TestCerbyToken");

let token: TestCerbyTokenInstance | null;

export const TestCerbyToken2 = async () => {
    if (!token) {
        token = await TestCerbyToken.new();

        return token;
    }

    return token;
};
