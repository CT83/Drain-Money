pragma solidity =0.5.16;

contract DrainMoney {
    event NewPool(uint256 poolId, address indexed owner);

    struct PoolMembers {
        address userAddress;
        uint256 amtContributed;
        address poolAddress;
    }

    struct Pool {
        uint256 hashPass;
        uint256 maxMembers;
        uint256 fixedInvestment;
        uint256 totalBalance;
        address owner;
        address[] poolMembers;
    }

    mapping(address => Pool) poolsToAddress;
    mapping(uint256 => uint256) passToPool;
    address[] public poolAccts;

    Pool[] public pools;

    //accept money from users
    function() external payable {
        require(msg.value > 0);
        //note down pay for this week
    }

    //func. create_pool(passphrase){ //if name not taken, create pool}
    function create_pool(
        string memory _passphrase,
        uint256 _maxMembers,
        uint256 _fixedInvestment
    ) public {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        Pool memory _pool = Pool(
            _hashPass,
            _maxMembers,
            _fixedInvestment,
            0,
            msg.sender,
            new address[](0)
        );
        uint256 id = pools.push(_pool) - 1;
        passToPool[id] = _hashPass;
        emit NewPool(id, msg.sender);
    }

    //function join_pool(address, passphrase){}

    //func. view_pool_details balance
    function getPoolDetails(string memory _passphrase)
        public
        view
        returns (address, uint256)
    {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        uint256 id;
        for (uint256 i = 0; i < pools.length; i++) {
            if (passToPool[id] == _hashPass) {
                id = i;
                address _owner = pools[id].owner;
                uint256 _maxMembers = pools[id].maxMembers;
                uint256 _fixedInvestment = pools[id].fixedInvestment;
                uint256 _totalBalance = pools[id].totalBalance;
                address[] memory poolMembers = pools[id].poolMembers;
                return (_owner, 1);
            }
        }
    }

    //func. invest_pool(address) {check if sender is a member of the pool}

    //func. mark_pool_defaulters(address, passphrase){}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
