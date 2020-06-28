const { assert } = require('console');
const truffleAssert = require('truffle-assertions');

const DrainMoney = artifacts.require("DrainMoney");

contract("DrainMoney", () => {
    it("deploys smart contract properly", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');
    })
})


contract("DrainMoney", accounts => {
    it("accepts eth from other addresses", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //transfer balance to contract
        var Web3 = require('web3');
        const url = "http://127.0.0.1:7545";
        var web3 = new Web3(new Web3.providers.HttpProvider(url));

        var contractAddress = DMContract.address;
        let oldBalance = await web3.eth.getBalance(contractAddress)
        await web3.eth.sendTransaction({ from: accounts[0], to: contractAddress, value: web3.utils.toWei("3", "ether") });

        let newBalance = await web3.eth.getBalance(contractAddress);
        assert(newBalance > oldBalance);

    })
})


contract("DrainMoney", accounts => {
    it("creates a pool and get details", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.create_pool("StrongPassPhrase", 5, 1, 100, 100, { from: accounts[0] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("StrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[0] == accounts[0]);
        assert(resPoolDets[1] == 1);
        assert(typeof (resPoolDets[2].toNumber()) == typeof (1));
    })
})

contract("DrainMoney", accounts => {
    it("fails if passphrase is invalid", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.create_pool("StrongPassPhrase", 5, 1, 100, 100, { from: accounts[0] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("WrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[0] != accounts[0]);
    })
})


contract("DrainMoney", accounts => {
    it("user is able to join a pool successfully", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.create_pool("StrongPassPhrase", 5, 1, 100, 100, { from: accounts[0] });

        //join a pool
        await DMContract.join_pool("StrongPassPhrase", { from: accounts[1] });
        await DMContract.join_pool("StrongPassPhrase", { from: accounts[2] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("StrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[3][0] == accounts[1]);
        assert(resPoolDets[3][1] == accounts[2]);
    })
})
