// var CTokenInterface = artifacts.require("CTokenInterface");
// var ComptrollerInterface = artifacts.require("ComptrollerInterface");
var MyDeFiProject = artifacts.require("MyDeFiProject");

module.exports = function (deployer) {
  deployer.deploy(MyDeFiProject,
    "0x6b175474e89094c44da98b954eedeac495271d0f",
    "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643",
    "0xc00e94cb662c3520282e6f5717214004a7f26888");
  // deployer.deploy(CTokenInterface);
  // deployer.deploy(ComptrollerInterface);
};