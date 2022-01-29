module.exports = {
  // contracts_directory: "../",
  contracts_build_directory: "./compiled",
  test_directory: "./test",

  networks: {
    development: {
      //host: "127.0.0.1",
      host: "sergey2.cerby.fi",
      port: 8545,
      gas: 30000000,
      network_id: "*",
    },
  },
};
