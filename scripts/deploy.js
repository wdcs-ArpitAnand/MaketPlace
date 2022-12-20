const { ethers } = require("ethers");

async function main(){
    const [deployer] = await hre.ethers.getSigners();

    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy();

    console.log("Token address :",token.address);
}


main()
.then(()=>process.exit(0))
.catch((error)=>{
    console.error(error);
    process.exit(1);
});