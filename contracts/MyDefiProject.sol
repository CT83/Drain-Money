pragma solidity =0.5.16;

import "./IERC20.sol";
import "./ComptrollerInterface.sol";
import "./CTokenInterface.sol";

contract MyDeFiProject {
    IERC20 dai;
    CTokenInterface cDai;
    ComptrollerInterface comptroller;

    constructor(
        address _dai,
        address _cDai,
        address _comptroller
    ) public {
        dai = IERC20(_dai);
        cDai = CTokenInterface(_cDai);
        comptroller = ComptrollerInterface(_comptroller);
    }

    function invest() external {
        dai.approve(address(cDai), 100);
        cDai.mint(100);
    }

    function cashOut() external {
        uint256 balance = cDai.balanceOf(address(this));
        cDai.redeem(balance);
    }
}
