async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());


    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy(
        ethers.utils.parseUnits("10000", 18),
        '0x1F98431c8aD98523631AE4a59f267346ea31F984',
        "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
    );

    console.log("Token address", token.address);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });
