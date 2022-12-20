/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle")

const ALCHEMY_API_KEY = "7a98c5896dfc400fb3389b6c86ce91dc";
const RINKBY_PRIVATE_KEY = "df37f93d3f55801d48a2cd3b4fd6bb5527b731afe74b4b4542f30eb1819d7fd6";
module.exports = {
  solidity: "0.8.9",

  networks:{
    ropsten:{
      url:`https://ropsten.infura.io/v3/${ALCHEMY_API_KEY}`,
      accounts:[`${RINKBY_PRIVATE_KEY }`],
    },
    localhost : {
      url:`http://127.0.0.1/8545`,
      accounts:[`${RINKBY_PRIVATE_KEY }`],
    }
  }
};
