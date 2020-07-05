pragma solidity =0.5.16;

import "./IERC20.sol";
import "./ComptrollerInterface.sol";
import "./CTokenInterface.sol";

contract DrainMoney {
    event NewPool(uint256 poolId, address indexed owner);

    struct PoolMember {
        address userAddress;
        uint256 amtContributed;
        uint256 poolId;
        uint256 lastPayment;
        bool defaulter;
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
        uint256 totalCTokens;
        uint256 currTerm;
    }

    mapping(uint256 => uint256) passToPool;
    address[] public poolAccts;

    Pool[] public pools;
    PoolMember[] public poolMembers;

    //accept money from users
    function() external payable {
        require(msg.value > 0);
        bool tranSuccess = false;
        //note down pay for this week
        for (uint256 id = 0; id < poolMembers.length; id++) {
            address _userAddress = poolMembers[id].userAddress;
            uint256 _fixedInvestment = pools[poolMembers[id].poolId]
                .fixedInvestment;
            // check if sender is part of pool, value is greater than fixed investment, cooldown has not passed
            if (_userAddress == msg.sender) {
                require(msg.value >= _fixedInvestment);
                require(
                    (poolMembers[id].lastPayment +
                        pools[poolMembers[id].poolId].frequency) >= now
                );
                poolMembers[id].amtContributed += msg.value;
                poolMembers[id].lastPayment = now;
                tranSuccess = true;
            }
        }
        require(tranSuccess);
    }

    function createPool(
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
            _frequency,
            0,
            1
        );
        uint256 id = pools.push(_pool) - 1;
        passToPool[id] = _hashPass;
        emit NewPool(id, msg.sender);
    }

    function joinPool(string memory _passphrase) public returns (bool) {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                address _userAddress = msg.sender;
                uint256 _amtContributed = 0;
                uint256 _poolId = id;
                uint256 _lastPayment = now;
                bool _defaulter = false;
                PoolMember memory poolMember = PoolMember(
                    _userAddress,
                    _amtContributed,
                    _poolId,
                    _lastPayment,
                    _defaulter
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

    function maintainAllPools() public returns (bool) {
        for (uint256 poolId; poolId < pools.length; poolId++) {
            Pool memory pool = pools[poolId];
            //increment terms
            //refund defaulters
            //kick out defaulters
        }
    }

    function refundAndMarkDefaulters(uint256 poolId) internal returns (bool) {
        Pool memory pool = pools[poolId];
        uint256 endTime = pool.startTime + (pool.frequency * pool.term);

        if (now < endTime) {
            for (uint256 memId = 0; memId < pool.poolMembers.length; memId++) {
                PoolMember memory member = poolMembers[memId];
                // check if member defaulted on the payments
                if (
                    member.lastPayment >=
                    (pool.currTerm * pool.frequency) + pool.startTime
                ) {
                    // refund user
                    address(uint160(member.userAddress)).transfer(
                        member.amtContributed
                    );
                    // mark person as defaulter
                    member.defaulter = true;
                }
            }
        }
        return true;
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
        public
        view
        returns (uint256)
    {
        uint256 _hashPass = uint256(keccak256(abi.encodePacked(_passphrase)));
        bool success = false;
        for (uint256 id = 0; id < pools.length; id++) {
            if (passToPool[id] == _hashPass) {
                success = true;
                return id;
            }
        }
        require(success);
    }

    function redeemCTokens(uint256 _amount) internal returns (uint256) {
        // return eth generated from cTokens
        return 0;
    }

    //func. cashout, cashes everyone out if term has expired
    function cashout(string memory _passphrase) public returns (bool) {
        maintainAllPools();
        uint256 poolId = getPoolIdForPass(_passphrase);
        Pool memory pool = pools[poolId];

        // count number of defaulters
        uint256 noOfDefaulters = 0;
        for (uint256 memId = 0; memId < pool.poolMembers.length; memId++) {
            PoolMember memory member = poolMembers[memId];
            if (member.defaulter) {
                noOfDefaulters++;
            }
        }

        // redeem cTokens from contract
        uint256 noOfCTokens = 0;
        redeemCTokens(noOfCTokens);

        // cash out all the defaulters
        for (uint256 memId = 0; memId < pool.poolMembers.length; memId++) {
            PoolMember memory member = poolMembers[memId];
            // transfer bal. to pool members
        }

        return true;
    }

    //func. auto cashout all if date is 30th

    //func. cashout_all(force) only owner can cashout_all, fails if cool down not passed

    //func. cashout(){cashes out only the single user}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
