import { expect } from "chai";
import { ethers } from "hardhat";

describe("Apartment opts", function () {
  before(async function () {
    this.Building = await ethers.getContractFactory("Building");
    this.Apartment = await ethers.getContractFactory("Apartment");
  });

  beforeEach(async function () {
    this.building = await this.Building.deploy();
    await this.building.deployed();

    this.apartment = await this.Apartment.deploy(this.building.address);
    await this.apartment.deployed();

    await this.building.setAptContract(this.apartment.address);
  });

  it("Should return merge two appts", async function () {
    const [deployer] = await ethers.getSigners();
    await this.building.mint(deployer.address, 1, 6000, 1);
    await this.building.buildApt(1, 1240, 1, deployer.address);
    await this.building.buildApt(1, 789, 1, deployer.address);

    await this.building.merge(1, [1, 2]);

    const merged = await this.apartment.properties(deployer.address, 0);

    expect(Number(merged.squareMeters) / 10 ** 18).to.equal(1240 + 789);
  });

  it("Should return split in three on appt", async function () {
    const [deployer] = await ethers.getSigners();
    await this.building.mint(deployer.address, 1, 6000, 1);
    await this.building.buildApt(1, 1240, 1, deployer.address);

    await this.building.split(1, 1, 3);

    const aptOne = await this.apartment.properties(deployer.address, 0);
    const aptTwo= await this.apartment.properties(deployer.address, 1);
    const aptThree= await this.apartment.properties(deployer.address, 2);

    const sqO = await Number(aptOne.squareMeters)/10**18;
    const sqT = await Number(aptTwo.squareMeters)/10**18;
    const sqTh = await Number(aptThree.squareMeters)/10**18;

    expect(sqO+sqT+sqTh).to.equal(1240);
  });
});
