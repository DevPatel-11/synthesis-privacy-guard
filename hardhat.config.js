require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    baseSepolia: {
      url: `https://sepolia.base.org`,
      accounts: [`0x` + process.env.PRIVATE_KEY || "0x" + "1".repeat(64)]
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  }
};
