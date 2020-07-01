pragma solidity =0.5.16;

contract DrainMoney {
    event NewPool(uint256 poolId, address indexed owner);

    struct PoolMembers {
        address userAddress;
        uint256 amtContributed;
        uint256 poolId;
        uint256 lastPayment;
    }

    struct Pool {
        uint256 hashPass;
        uint256 maxMembers;
        uint256 fixedInvestment;
        uint256 totalBalance;
        address owner;
        uint256[] poolMembers;
        uint256 startTime;
        uint256 term;
        uint256 frequency;
    }

    mapping(uint256 => uint256) passToPool;
    address[] public poolAccts;

    Pool[] public pools;
    PoolMembers[] public poolMembers;

    //accept money from users
    function() external payable {
        require(msg.value > 0);
        //note down pay for this week
        for (uint256 id = 0; id < poolMembers.length; id++) {
            address _userAddress = poolMembers[id].userAddress;
            uint256 _fixedInvestment = pools[poolMembers[id].poolId]
                .fixedInvestment;
            // check if sender is part of pool, value is greater than fixed investment, cooldown has not passed
            if (_userAddress == msg.sender) {
                require(msg.value >= _fixedInvestment);
                poolMembers[id].amtContributed += msg.value;
                poolMembers[id].lastPayment = now;
            }
        }
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
            new uint256[](0),
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
                address _userAddress = msg.sender;
                uint256 _amtContributed = 0;
                uint256 _poolId = id;
                uint256 _lastPayment = now;
                PoolMembers memory poolMember = PoolMembers(
                    _userAddress,
                    _amtContributed,
                    _poolId,
                    _lastPayment
                );
                uint256 pmId = poolMembers.push(poolMember);
                pools[id].poolMembers.push(pmId);
                return true;
            }
        }
        return false;
    }

    function getPoolMembers(uint256 _id)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        address _userAddress = poolMembers[_id].userAddress;
        uint256 _amtContributed = poolMembers[_id].amtContributed;
        uint256 _poolId = poolMembers[_id].poolId;
        uint256 _lastPayment = poolMembers[_id].lastPayment;
        return (_userAddress, _amtContributed, _poolId, _lastPayment);
    }

    function getPoolDetails(string memory _passphrase)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256[] memory,
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
                uint256[] memory _poolMembers = pools[id].poolMembers;
                uint256 _startTime = pools[id].startTime;
                uint256 _term = pools[id].term;
                uint256 _frequency = pools[id].frequency;
                return (
                    _owner,
                    _fixedInvestment,
                    _totalBalance,
                    _poolMembers,
                    _startTime,
                    _term,
                    _frequency
                );
            }
        }
    }

    //func. invest_pool(address) {check if sender is a member of the pool}
    function invest(string memory _passphrase) public returns (bool) {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                // pools[id].poolMembers.push(pmId);
                // code to invest money
                return true;
            }
        }
        return false;
    }

    //func. mark_pool_defaulters(address, passphrase){}
    function cashout_defaulters(string memory _passphrase)
        public
        returns (bool)
    {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                for (
                    uint256 iter = 0;
                    iter < pools[id].poolMembers.length;
                    iter++
                ) {
                    // check if the last payment was done within the freq. time
                    if (
                        now -
                            poolMembers[pools[id].poolMembers[iter]]
                                .lastPayment >
                        pools[id].frequency && // now - lastpayment older than frequency
                        now >
                        pools[id].startTime +
                            (pools[id].frequency * pools[id].term) // now older than (start + (freq*term))
                    ) {
                        address payable _addr = address(
                            uint160(
                                poolMembers[pools[id].poolMembers[iter]]
                                    .userAddress
                            )
                        );
                        _addr.transfer(
                            poolMembers[pools[id].poolMembers[iter]]
                                .amtContributed
                        );
                    }
                }

                return true;
            }
        }
        return false;
    }

    function getPoolIdForPass(string memory _passphrase)
        internal
        view
        returns (uint256)
    {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                return id;
            }
        }
    }

    //func. cashout, cashes everyone out if term has expired
    function cashout(string memory _passphrase) public returns (bool) {
        return true;
    }

    //func. auto cashout all if date is 30th

    //func. cashout_all(force) only owner can cashout_all, fails if cool down not passed

    //func. cashout(){cashes out only the single user}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
