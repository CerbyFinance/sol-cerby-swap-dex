mkdir  -p compiled

solc -o ../bin/ --bin --abi --optimize --overwrite ../TestCerbyToken.sol
solc -o ../bin/ --bin --abi --optimize --overwrite ../TestCerUsdToken.sol
solc -o ../bin/ --bin --abi --optimize --overwrite ../TestUsdcToken.sol
solc -o ../bin/ --bin --abi --optimize --overwrite ../CerbySwapV1.sol
solc -o ../bin/ --bin --abi --optimize --overwrite ../Migrations.sol

cp ../bin/*.abi ./abis