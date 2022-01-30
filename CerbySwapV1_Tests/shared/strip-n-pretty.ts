import fs from "fs";
import path from "path";

const compiledPath = path.resolve(__dirname, "../compiled");
const binPath = path.resolve(__dirname, "../../bin");

const folder = fs.readdirSync(binPath);

folder
  .filter((item) => item.includes("json") && !item.includes("solc-output"))
  .forEach((item) => {
    const { contractName, abi, bytecode } = JSON.parse(
      fs.readFileSync(binPath + "/" + item, "utf8")
    );

    const toSave = {
      contractName,
      abi,
      bytecode,
    };

    const pathToSave = path.resolve(compiledPath + "/" + item);

    fs.writeFileSync(pathToSave, JSON.stringify(toSave, null, 2));
  });
