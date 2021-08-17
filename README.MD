### DECENT LABS ASSIGNMENT

## Installation
1. git clone repository.
2. ```npm install``` to install hardhat and npm packages.
3. Create a .env file and add MNEMONIC AND secret variables for Alchemy or Infura url.
```
ALCHEMY_URL_MAINNET= ...
ALCHEMY_URL_ROPSTEN= ...
ALCHEMY_URL_KOVAN= ...
MNEMONIC= ...
```

## Run Tests
```npx hardhat test``` for mainnet fork (default)
```npx hardhat test --network [desired network]``` etc.

## Deployment of contract
Inside the script folder there is a deploy.js file which will deploy the Token.sol (main contract).  
```npx hardhat run ./scripts/deploy.js --network [desired network]```


