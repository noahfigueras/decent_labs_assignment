require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('dotenv').config();

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.7.6"
            },
        ],
        overrides: {
            "": {
                version: "0.7.5",
                settings: { }
            }
        },
    },
    networks: {
        hardhat: {
            forking: {
                url: process.env.ALCHEMY_URL_ROPSTEN,
            },
        },
        kovan: {
            url: process.env.ALCHEMY_URL_KOVAN,
        },
        ropsten: {
            url: process.env.ALCHEMY_URL_ROPSTEN,
            accounts: {
                mnemonic: process.env.MNEMONIC,
            }
        }
    },
    mocha: {
        timeout: 140000
    }
};

