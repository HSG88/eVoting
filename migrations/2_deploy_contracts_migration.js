const { MerkleTree } = require('../helper/merkletree.js')
var Migrations = artifacts.require("Migrations.sol");
const eVote = artifacts.require("eVote.sol")
const Crypto = artifacts.require("Crypto.sol")

module.exports = function(deployer, network, accounts) {
    let usersMerkleTree = new MerkleTree(accounts.slice(1,accounts.length-1))
    deployer.deploy(Migrations);
    deployer.deploy(Crypto).then(function() {
        return deployer.deploy(eVote, Crypto.address, usersMerkleTree.getHexRoot(),100,100,100,100,{from:accounts[0], value:web3.utils.toWei("1","ether")})
    });
};