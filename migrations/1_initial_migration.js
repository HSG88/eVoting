var Migrations = artifacts.require("Migrations.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Migrations);
  let cryptoInstance, eVoteInstance
  const admin = accounts[0]
  
};