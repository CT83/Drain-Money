pragma solidity =0.5.16;

contract DrainMoney {
    address owner;
    address payable nextToKin;
    uint256 lastActive;
    bool drained;
}
