const { assert } = require('console');

const DrainMoney = artifacts.require("DrainMoney");

contract("DrainMoney", () => {
    it("Should deploy smart contract properly", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');
    })
})


contract("DeadMansSwitchContract", accounts => {
    it("Register new address successfully", async () => {
        const DMSContract = await DeadMansSwitchContract.deployed();
        assert(DMSContract.address !== '');

        // const time = Math.round(new Date().getTime() / 1000);
        await DMSContract.register(accounts[1], { from: accounts[0] });
        await DMSContract.still_alive({ from: accounts[0] });

        const res = await DMSContract.getData();
        assert(res[0] == accounts[0])
        assert(res[1] <= accounts[1])
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