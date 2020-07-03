const { assert } = require('console');
const truffleAssert = require('truffle-assertions');

const MyDeFiProject = artifacts.require("MyDeFiProject");

contract("MyDeFiProject", () => {
    it("deploys smart contract properly", async () => {
        const DeFiContract = await MyDeFiProject.deployed();
        assert(DeFiContract.address !== '');
    })
})
