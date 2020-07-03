const { assert } = require('console');
const truffleAssert = require('truffle-assertions');

const MyDeFiProject = artifacts.require("MyDeFiProject");

contract("MyDeFiProject", () => {
    it("deploys smart contract properly", async () => {
        const DeFiContract = await MyDeFiProject.deployed();
        assert(DeFiContract.address !== '');
    })
})

const { BN, ether, balance } = require('openzeppelin-test-helpers');
const { expect } = require('chai');
const { asyncForEach } = require('./utils');

// ABI
const daiABI = require('./abi/dai');

// userAddress must be unlocked using --unlock ADDRESS
const userAddress = '0x256e2e8D5B62859653fBbEB2B45626C0B958b0f3';
const daiAddress = '0x6b175474e89094c44da98b954eedeac495271d0f';
const daiContract = new web3.eth.Contract(daiABI, daiAddress);

contract('MyDeFiProject', async accounts => {
    it('should send ether to the DAI address', async () => {
        // Send 0.1 eth to userAddress to have gas to send an ERC20 tx.
        await web3.eth.sendTransaction({
            from: accounts[0],
            to: userAddress,
            value: ether('0.1')
        });
        const ethBalance = await balance.current(userAddress);
        expect(new BN(ethBalance)).to.be.bignumber.least(new BN(ether('0.1')));
    });

    it('should mint DAI for our first 5 generated accounts', async () => {
        // Get 100 DAI for first 5 accounts
        await asyncForEach(accounts.slice(0, 5), async account => {
            // daiAddress is passed to ganache-cli with flag `--unlock`
            // so we can use the `transfer` method
            await daiContract.methods
                .transfer(account, ether('100').toString())
                .send({ from: userAddress, gasLimit: 800000 });
            const daiBalance = await daiContract.methods.balanceOf(account).call();
            expect(new BN(daiBalance)).to.be.bignumber.least(ether('100'));
        });
    });
});