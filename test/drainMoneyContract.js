const { assert } = require('console');
const DrainMoney = artifacts.require("DrainMoney");

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract("DrainMoney", () => {
    it("deploys smart contract properly", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');
    })
})

contract("DrainMoney", accounts => {
    it("creates a pool and get details", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.createPool("StrongPassPhrase", 5, 1, 100, 100, { from: accounts[0] });

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
        await DMContract.createPool("StrongPassPhrase", 5, 1, 100, 100, { from: accounts[0] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("WrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[0] == 0x0000000000000000000000000000000000000000);
    })
})


contract("DrainMoney", accounts => {
    it("user is able to join a pool successfully", async () => {
        const DMContract = await DrainMoney.deployed();
        assert(DMContract.address !== '');

        //create pool
        await DMContract.createPool("StrongPassPhrase", 5, 1, 100, 100, { from: accounts[0] });

        //join a pool
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[1] });
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[2] });

        //get pool details
        let resPoolDets = await DMContract.getPoolDetails("StrongPassPhrase", { from: accounts[0] });
        assert(resPoolDets[3][0].toNumber() == 1);
        assert(resPoolDets[3][1].toNumber() == 2);

        var resPoolMembs = await DMContract.getPoolMembers(0);
        assert(resPoolMembs[0] == accounts[1]);

        resPoolMembs = await DMContract.getPoolMembers(1);
        assert(resPoolMembs[0] == accounts[2]);
    })
})

contract("DrainMoney", accounts => {
    it("creates a record when user from a pool invests", async () => {
        const DMContract = await DrainMoney.deployed();
        var contractAddress = DMContract.address;
        assert(contractAddress !== '');

        //create pool
        await DMContract.createPool("StrongPassPhrase", 5, web3.utils.toWei("1", "ether"), 4, 100, { from: accounts[0] });

        //join a pool
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[1] });
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[2] });
        var resPoolMembs = await DMContract.getPoolMembers(0);
        assert(resPoolMembs[0] == accounts[1]);

        //send money & check updated balance
        var contractOldBalance = await web3.eth.getBalance(contractAddress);
        await web3.eth.sendTransaction({ from: accounts[1], to: contractAddress, value: web3.utils.toWei("2", "ether") });
        resPoolMembs = await DMContract.getPoolMembers(0);
        assert(resPoolMembs[0] == accounts[1]);
        assert(web3.utils.fromWei(resPoolMembs[1]) == 2);
        assert(await web3.eth.getBalance(contractAddress) > contractOldBalance);
    })
})

contract("DrainMoney", accounts => {
    it("rejects transactions lesser than fixed amount of the pool", async () => {
        const DMContract = await DrainMoney.deployed();
        var contractAddress = DMContract.address;
        await DMContract.createPool("StrongPassPhrase", 5, web3.utils.toWei("1", "ether"), 1, 100, { from: accounts[0] });
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[1] });

        //send money less than fixed investment and see if it fails
        contractOldBalance = await web3.eth.getBalance(contractAddress);
        try {
            await web3.eth.sendTransaction({ from: accounts[1], to: contractAddress, value: web3.utils.toWei("0.5", "ether") });
        } catch (err) {
            assert(err)
        }
        var resPoolMembs = await DMContract.getPoolMembers(0);
        assert(resPoolMembs[0] == accounts[1]);
        assert(web3.utils.fromWei(resPoolMembs[1]) == 0);
        assert(await web3.eth.getBalance(contractAddress) == contractOldBalance);
    })
});

contract("DrainMoney", accounts => {
    it("refunds defaulters in a pool", async () => {
        const DMContract = await DrainMoney.deployed();
        var contractAddress = DMContract.address;
        await DMContract.createPool("StrongPassPhrase", 5, web3.utils.toWei("1", "ether"), 4, 1, { from: accounts[0] });
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[1] });

        //send money in time
        await web3.eth.sendTransaction({ from: accounts[1], to: contractAddress, value: web3.utils.toWei("1", "ether") });

        //send money later than frequency
        await timeout(1100);
        var error;
        try {
            await web3.eth.sendTransaction({ from: accounts[1], to: contractAddress, value: web3.utils.toWei("1", "ether") });
        } catch (e) {
            error = e;
        }
        assert(error)
    })
})

contract("DrainMoney", accounts => {
    it("returns correct pool id for respective passphrase", async () => {
        const DMContract = await DrainMoney.deployed();
        var contractAddress = DMContract.address;
        await DMContract.createPool("StrongPassPhrase1", 5, web3.utils.toWei("1", "ether"), 4, 1, { from: accounts[0] });
        await DMContract.createPool("StrongPassPhrase2", 5, web3.utils.toWei("1", "ether"), 4, 1, { from: accounts[1] });
        await DMContract.createPool("StrongPassPhrase3", 5, web3.utils.toWei("1", "ether"), 4, 1, { from: accounts[2] });

        var id

        // return poolid 3
        id = await DMContract.getPoolIdForPass("StrongPassPhrase3");
        assert(id.toNumber() == 2);

        // return poolid 1
        id = await DMContract.getPoolIdForPass("StrongPassPhrase1");
        assert(id.toNumber() == 0);

        // return poolid 2
        id = await DMContract.getPoolIdForPass("StrongPassPhrase2");
        assert(id.toNumber() == 1);

    })
})
