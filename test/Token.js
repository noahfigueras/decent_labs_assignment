const {expect} = require('chai');

describe("Decent Lab Assignment Token Contract testing", function() {

    //Defining variables
    let Token;
    let token;
    let impAddr;
    let owner;
    let addr1;
    let initialSupply = ethers.utils.parseUnits("10000", 18);
    let uniswapV3FactoryAddress = '0x1F98431c8aD98523631AE4a59f267346ea31F984';
    let WETHAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
    // let WETHAddress = '0xd0a1e359811322d97991e03f863a0c30c2cf029c'; //WETH adress for testnet
    let nonfungiblePositionManagerAddr = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88";
    let poolFee = 3000;

    //Settings before each test
    beforeEach(async function () {
        //Impersonate Address for testing on mainnet fork
        
        await hre.network.provider.request({
              method: "hardhat_impersonateAccount",
              params: ["0x0548F59fEE79f8832C299e01dCA5c76F034F558e"],
        });
        impAddr = await ethers.getSigner('0x0548F59fEE79f8832C299e01dCA5c76F034F558e'); 

        [owner, addr1] = await ethers.getSigners();
        Token = await ethers.getContractFactory('Token');
        token = await Token.deploy(
            initialSupply,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddr
        );
    })

    //Testing all paramaters are Initialized correctly on deployment
    describe("Token Deployment", function() {
        it("Should assign the total supply of tokens to owner", async function() {
            console.log(owner.address)
            const ownerBalance = await token.balanceOf(owner.address); 
            expect(await token.totalSupply()).to.equal(ownerBalance);
        })
    })

    //UniswapV3pool creates correctly
    describe("UniswapV3", function() {
        it("creates pool DLAT/ETH correctly", async function(){
            let bool = false;
            const tx = await token.createPool(WETHAddress, poolFee);
            const reciept = await tx.wait()

            //Checking if address of new pool is returned
            if(reciept.events[2].args.pool) {
                bool = true;
            }

            expect(bool).to.equal(true);
            //Checking for event 
            expect(reciept.events[2].event).to.equal('PoolSuccessfullyCreated');
        });

        it("should only allow the owner of contract to createPool", async function() {
            let bool = true;
            try {
                await token.connect(addr1).createPool(WETHAddress, poolFee);
            } catch (e) {
                bool = false;
            }
            expect(bool).to.equal(false);
        });

        it("Provides Liquidity to the pool", async function() {
            await token.changeOwner("0x0548F59fEE79f8832C299e01dCA5c76F034F558e");
            const tx = await token.connect(impAddr).createPool(WETHAddress, poolFee);
            tx.wait()

            await token.connect(impAddr).seedLiquidity(WETHAddress, 1000, 500);
        });
    })
})


