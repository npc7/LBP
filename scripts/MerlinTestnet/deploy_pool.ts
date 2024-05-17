import { ethers, run } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // DOG-pool
  // 1714046400 Thu Apr 25 2024 12:00:00 GMT+0000
  // 1716379200 Wed May 22 2024 12:00:00 GMT+0000
  // 1B
  //   const param = [];
  const contract = await ethers.deployContract("LiquidityBootstrapPool");

  await contract.waitForDeployment();

  console.log("LiquidityBootstrapPool:", contract.target);

  console.log(
    ` deployed to https://testnet-scan.merlinchain.io/address/${contract.target}`
  );

  await run("verify:verify", {
    address: contract.target,
    contract:
      "contracts/pool/LiquidityBootstrapPool.sol:LiquidityBootstrapPool",
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
