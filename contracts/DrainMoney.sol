pragma solidity >=0.5.16;

interface Erc20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);
}

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    // Added balanceOf
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract DrainMoney {
    event NewPool(uint256 poolId, address indexed owner);

    address payable cEtherContract = address(0);

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
                        pools[poolMembers[id].poolId].frequency) >=
                        block.timestamp
                );
                poolMembers[id].amtContributed += msg.value;
                poolMembers[id].lastPayment = block.timestamp;
                pools[poolMembers[id].poolId].totalBalance += msg.value;
                tranSuccess = true;
            }
        }
        require(tranSuccess);
    }

    event MyLog(string, uint256);

    function supplyEthToCompound(address payable _cEtherContract)
        public
        payable
        returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        cToken.mint.value(msg.value).gas(250000)();
        return true;
    }

    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) public returns (uint256) {
        // Create a reference to the underlying asset contract, like DAI.
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, _numTokensToSupply);

        // Mint cTokens
        uint256 mintResult = cToken.mint(_numTokensToSupply);
        return mintResult;
    }

    function redeemCErc20Tokens(
        uint256 amount,
        bool redeemType,
        address _cErc20Contract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/developers/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
    }

    function redeemCEth(
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
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
            block.timestamp,
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
                uint256 _lastPayment = block.timestamp;
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

    function _supplyEthToCompound(uint256 _value)
        public
        payable
        returns (uint256)
    {
        // make sure the contract has enough money
        // require(address(this).balance >= _value);
        CEth cToken = CEth(cEtherContract);
        uint256 prevCBal = cToken.balanceOf(address(this));
        cToken.mint.value(_value).gas(1)();
        uint256 mintedCToken = cToken.balanceOf(address(this)) - prevCBal;
        return mintedCToken;
    }

    function invest(string memory _passphrase) public returns (bool) {
        uint256 poolId = getPoolIdForPass(_passphrase);
        Pool memory pool = pools[poolId];
        // require(pool.owner == msg.sender); // make sure pool owner is issuing the invest command
        uint256 mintedCTokens = _supplyEthToCompound(pool.totalBalance);
        pool.totalBalance = 0;
        pool.totalCTokens += mintedCTokens;
    }

    function maintainAllPools() public returns (bool) {
        for (uint256 poolId; poolId < pools.length; poolId++) {
            // Pool memory pool = pools[poolId];
            setPoolTerms(poolId);
            refundAndMarkDefaulters(poolId);
        }
    }

    function setPoolTerms(uint256 poolId) public returns (bool) {
        Pool memory pool = pools[poolId];
        pool.currTerm = (block.timestamp - pool.startTime);
        return true;
    }

    function refundAndMarkDefaulters(uint256 poolId) internal returns (bool) {
        Pool memory pool = pools[poolId];
        uint256 endTime = pool.startTime + (pool.frequency * pool.term);

        if (block.timestamp < endTime) {
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

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
