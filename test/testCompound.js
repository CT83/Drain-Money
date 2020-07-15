const { assert } = require('console');
const DrainMoney = artifacts.require("DrainMoney");

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract("DrainMoney", accounts => {
    it("allows user to add money to pool &, invest in cEth", async () => {
        const DMContract = await DrainMoney.deployed();
        var contractAddress = DMContract.address;
        assert(contractAddress !== '');

        //create pool
        await DMContract.createPool("StrongPassPhrase", 5, web3.utils.toWei("1", "ether"), 4, 100, { from: accounts[0] });

        //join a pool
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[1] });
        await DMContract.joinPool("StrongPassPhrase", { from: accounts[2] });

        //send money
        await web3.eth.sendTransaction({ from: accounts[1], to: contractAddress, value: web3.utils.toWei("2", "ether") });
        var a = await web3.eth.getBalance(contractAddress);
        console.log(a)
        await DMContract.invest("StrongPassPhrase", { from: accounts[0] })
        var a = await web3.eth.getBalance(contractAddress);
        console.log(a)
    })
})