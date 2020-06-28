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
        uint256 startTime;
        uint256 term;
        uint256 frequency;
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

    function create_pool(
        string memory _passphrase,
        uint256 _maxMembers,
        uint256 _fixedInvestment,
        uint256 _term,
        uint256 _frequency
    ) public {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        Pool memory _pool = Pool(
            _hashPass,
            _maxMembers,
            _fixedInvestment,
            0,
            msg.sender,
            new address[](0),
            now,
            _term,
            _frequency
        );
        uint256 id = pools.push(_pool) - 1;
        passToPool[id] = _hashPass;
        emit NewPool(id, msg.sender);
    }

    function join_pool(string memory _passphrase) public returns (bool) {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                pools[id].poolMembers.push(msg.sender);
                return true;
            }
        }
        return false;
    }

    function getPoolDetails(string memory _passphrase)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            address[] memory,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                address _owner = pools[id].owner;
                uint256 _fixedInvestment = pools[id].fixedInvestment;
                uint256 _totalBalance = pools[id].totalBalance;
                address[] memory poolMembers = pools[id].poolMembers;
                uint256 _startTime = pools[id].startTime;
                uint256 _term = pools[id].term;
                uint256 _frequency = pools[id].frequency;
                return (
                    _owner,
                    _fixedInvestment,
                    _totalBalance,
                    poolMembers,
                    _startTime,
                    _term,
                    _frequency
                );
            }
        }
    }

    //func. invest_pool(address) {check if sender is a member of the pool}

    //func. mark_pool_defaulters(address, passphrase){}

    //func. auto cashout all if date is 30th

    //func. cashout_all(force) only owner can cashout_all, fails if cool down not passed

    //func. cashout(){cashes out only the single user}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
