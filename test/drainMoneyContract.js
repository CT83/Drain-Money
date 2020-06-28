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
    it("creates a pool and returns pool address", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.create_pool("StrongPassPhrase", 5, 1, { from: accounts[0] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("StrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[0] == accounts[0]);
        assert(resPoolDets[1] == 5);
        assert(resPoolDets[2] == 1);
        assert(typeof (resPoolDets[3].toNumber()) == typeof (1));
    })
})

contract("DrainMoney", accounts => {
    it("fails if passphrase is invalid", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.create_pool("StrongPassPhrase", 5, 1, { from: accounts[0] });

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
        await DMContract.create_pool("StrongPassPhrase", 5, 1, { from: accounts[0] });

        //join a pool
        await DMContract.join_pool("StrongPassPhrase", { from: accounts[1] });
        await DMContract.join_pool("StrongPassPhrase", { from: accounts[2] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("StrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[4][0] == accounts[1]);
        assert(resPoolDets[4][1] == accounts[2]);
    })
})

contract("DeadMansSwitchContract", accounts => {
    it("Check if alive beacon can be sent successfully", async () => {
        const DMSContract = await DeadMansSwitchContract.deployed();
        assert(DMSContract.address !== '');

        await DMSContract.register(accounts[1], { from: accounts[0] });
        const time = Math.round(new Date().getTime() / 1000);
        await DMSContract.still_alive({ from: accounts[0] });

        const res = await DMSContract.getData();
        assert(res[0] == accounts[0])
        assert(res[1] <= accounts[1])
        assert(res[2].toNumber() <= time + 1000)
    })
})

contract("DeadMansSwitchContract", accounts => {
    it("Check if drain on death works", async () => {
        const DMSContract = await DeadMansSwitchContract.deployed();
        assert(DMSContract.address !== '');

        await DMSContract.register(accounts[1], { from: accounts[0] });
        const time = Math.round(new Date().getTime() / 1000);
        await DMSContract.still_alive({ from: accounts[0] });

        //transfer balance to contract
        var Web3 = require('web3');
        const url = "http://127.0.0.1:7545";
        var web3 = new Web3(new Web3.providers.HttpProvider(url));

        var contractAddress = DMSContract.address;
        let send = await web3.eth.sendTransaction({ from: accounts[0], to: contractAddress, value: web3.utils.toWei("3", "ether") });
        const ownerOldBalance = await web3.eth.getBalance(accounts[0])
        const nextToKinOldBalance = await web3.eth.getBalance(accounts[1])

        const res = await DMSContract.getData();

        assert(res[0] == accounts[0])
        assert(res[1] <= accounts[1])
        assert(res[2].toNumber() <= time + 1000)

        await DMSContract.drainIfDead();

        const resDrained = await DMSContract.getDrained();
        assert(resDrained == false);
        const { promisify } = require('util')
        const sleep = promisify(setTimeout)

        await DMSContract.drainIfDead();
        const resDrained2 = await DMSContract.getDrained();
        assert(resDrained2 == false);

        await sleep(3000)
        await DMSContract.drainIfDead();
        const resDrained3 = await DMSContract.getDrained();
        assert(resDrained3 == true);

        const ownerNewBalance = await web3.eth.getBalance(accounts[0])
        const nextToKinNewBalance = await web3.eth.getBalance(accounts[1])

        assert(ownerNewBalance < ownerOldBalance);
        assert(nextToKinNewBalance > nextToKinOldBalance);
    })
})