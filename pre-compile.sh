mkdir  -p compiled

solc -o ./bin/ --bin --abi --optimize --overwrite ./contracts/TestCerbyToken.sol
solc -o ./bin/ --bin --abi --optimize --overwrite ./contracts/TestCerUsdToken.sol
solc -o ./bin/ --bin --abi --optimize --overwrite ./contracts/TestUsdcToken.sol
solc -o ./bin/ --bin --abi --optimize --overwrite ./contracts/CerbySwapV1_Vault.sol
solc -o ./bin/ --bin --abi --optimize --overwrite ./contracts/CerbySwapV1.sol
solc -o ./bin/ --bin --abi --optimize --overwrite ./contracts/Migrations.sol

cp ./bin/*.abi ./abis