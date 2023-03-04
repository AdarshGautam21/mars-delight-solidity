const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {

  // Define a list of wallets to airdrop NFTs
  const airdropAddresses = [
    '0x9F11B0E1CfE05AEA6152de28E1017875B9b5D2f3',
    '0xdFC37f7e7B95F780b13A856530ACed26A2A4B170',
    '0x7f9783E71ad215B15b8955aec00DF2fF84927136',
  ];

  const factory = await hre.ethers.getContractFactory("NFTAirdrop");
  const [owner] = await hre.ethers.getSigners();
  const contract = await factory.deploy();

  await contract.deployed();
  console.log("Contract deployed to: ", contract.address);
  console.log("Contract deployed by (Owner): ", owner.address, "\n");

  let txn;
  txn = await contract.airdropNfts(airdropAddresses);
  await txn.wait();
  console.log("NFTs airdropped successfully!");

  console.log("\nCurrent NFT balances:")
  for (let i = 0; i < airdropAddresses.length; i++) {
    let bal = await contract.balanceOf(airdropAddresses[i]);
    console.log(`${i + 1}. ${airdropAddresses[i]}: ${bal}`);
  }

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });