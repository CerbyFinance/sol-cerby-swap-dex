module.exports = {
    plugins: ["solidity-coverage"],
    networks: {
        development: {
            host: "127.0.0.1",
            //host: "sergey2.cerby.fi",
            port: 8545,
            gasLimit: 8000000,
            network_id: 5777
        },
        /* rinkeby: {
            provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infura_id}`),
            network_id: 4,
            skipDryRun: true
        },
        ropsten: {
            provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/${infura_id}`),
            network_id: 3,
            skipDryRun: true
        }*/
    },
    /*mocha: {
        useColors: true,
        reporter: "eth-gas-reporter",
        reporterOptions: {
            currency: "USD",
            gasPrice: 5
        }
    },*/
    compilers: {
        solc: {
            version: "^0.8.14",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                },
            }
        }
    }
};
