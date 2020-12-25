const FiatPresale = artifacts.require("FiatPresale");
const DAI = artifacts.require("DAI");
const VNTW = artifacts.require("VNTW");

module.exports = async (deployer) => {
  deployer.deploy(DAI);
  deployer.deploy(VNTW);
  const dai = await DAI.deployed();
  const vntw = await VNTW.deployed();

  deployer.deploy(FiatPresale, vntw.address, dai.address);
};
