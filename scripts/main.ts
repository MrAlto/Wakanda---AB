const { ethers } = require("hardhat");
import BigNumber from "bignumber.js";

async function deploy() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log("\r\n");

  const Building = await ethers.getContractFactory("Building");

  const building = await Building.deploy();

  const Apartment = await ethers.getContractFactory("Apartment");

  const apartment = await Apartment.deploy(building.address);

  // Initialize
  await building.setAptContract(apartment.address);

  return { deployer, building, apartment };
}

async function modeling(deployer: any, building: any) {
  /* Mint Building NFT : Owner , Building Id, Total square meters, Nb of floors */
  await building.mint(deployer.address, 1, 6000, 4);

  /* Build apartments NFT : Building Id, Square meters, Floor, Owner */
  await building.buildApt(1, 1000, 1, deployer.address);
  await building.buildApt(1, 1000, 2, deployer.address);
  await building.buildApt(1, 600, 3, deployer.address);
  await building.buildApt(1, 700, 3, deployer.address);
  await building.buildApt(1, 600, 4, deployer.address);
  await building.buildApt(1, 700, 4, deployer.address);
}

async function remodeling(deployer: any, building: any) {
  /* Split apartments NFT : Building Id, Apartment Id, Number of split */
  await building.split(1, 1, 2);
  await building.split(1, 2, 2);
  await building.split(1, 6, 2);

  /* Merge apartments NFT : Building Id, Apartment Id [] */
  await building.merge(1, [3, 4]);
}

async function main() {
  let { deployer, building, apartment } = await deploy();

  // Initialize Modeling
  await modeling(deployer, building);

  const listApt = [];

  // All apartments owned by deployer
  const OneA = await apartment.properties(deployer.address, 0);
  const TwoA = await apartment.properties(deployer.address, 1);
  const ThreeA = await apartment.properties(deployer.address, 2);
  const ThreeB = await apartment.properties(deployer.address, 3);
  const FourA = await apartment.properties(deployer.address, 4);
  const FourB = await apartment.properties(deployer.address, 5);

  listApt.push(OneA);
  listApt.push(TwoA);
  listApt.push(ThreeA);
  listApt.push(ThreeB);
  listApt.push(FourA);
  listApt.push(FourB);

  // Print Values
  listApt.forEach((apt) => {
    console.log("Apartment n°", Number(apt.tokenId));
    console.log("Square meters :", Number(apt.squareMeters) / 10 ** 18, " m2");
    console.log("Floor :", apt.floor);
    console.log("\r\n");
  });

  // Remodeling
  console.log("======= Remodeling ======= ");

  await remodeling(deployer, building);
  const listApt_remodeled = [];

  // All apartments owned by deployer
  const OneABis = await apartment.properties(deployer.address, 0);
  const OneBBis = await apartment.properties(deployer.address, 1);
  const TwoABis = await apartment.properties(deployer.address, 2);
  const TwoBBis = await apartment.properties(deployer.address, 3);
  const ThreeABis = await apartment.properties(deployer.address, 4);
  const FourABis = await apartment.properties(deployer.address, 5);
  const FourBBis = await apartment.properties(deployer.address, 6);
  const FourCBis = await apartment.properties(deployer.address, 7);

  listApt_remodeled.push(OneABis);
  listApt_remodeled.push(OneBBis);
  listApt_remodeled.push(TwoABis);
  listApt_remodeled.push(TwoBBis);
  listApt_remodeled.push(ThreeABis);
  listApt_remodeled.push(FourABis);
  listApt_remodeled.push(FourBBis);
  listApt_remodeled.push(FourCBis);

  // Print Values
  listApt_remodeled.forEach((apt) => {
    console.log("Apartment n°", Number(apt.tokenId));
    console.log("Square meters :", Number(apt.squareMeters) / 10 ** 18, " m2");
    console.log("Floor :", apt.floor);
    console.log("\r\n");
  });
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
