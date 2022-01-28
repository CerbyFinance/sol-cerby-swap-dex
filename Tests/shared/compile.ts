import { exec } from "child_process";
import fs from "fs";
import path from "path";
import util from "util";
const execP = util.promisify(exec);

const compiledPath = path.resolve(__dirname, "../compiled");
const binPath = path.resolve(__dirname, "../../bin");

const ignite = async () => {
  const { stdout, stderr } = await execP(
    path.resolve(__dirname, "../pre-compile.sh"),
  ).catch(e => ({ stdout: "", stderr: e }));

  console.log(stderr);
  console.log(stdout);

  const folder = fs.readdirSync(binPath);

  const groupedByName = folder.reduce((acc, val) => {
    const [fileName] = val.split(".");

    acc[fileName] = [...(acc[fileName] || []), val];

    return acc;
  }, {} as { [key: string]: string[] });

  Object.entries(groupedByName).forEach(([contractName, values], _) => {
    const abiFileName = values.find(item => item.includes("abi"))!;
    const binFileName = values.find(item => item.includes("bin"))!;

    const abi = JSON.parse(
      fs.readFileSync(binPath + "/" + abiFileName, "utf8"),
    );
    const bytecode = fs.readFileSync(binPath + "/" + binFileName, "utf8");

    const toSave = {
      contractName,
      abi,
      bytecode,
    };

    const pathToSave = path.resolve(
      compiledPath + "/" + contractName + ".json",
    );

    fs.writeFileSync(pathToSave, JSON.stringify(toSave, null, 2));
  });
};

ignite();
