// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public stakingToken;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public stakeTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) private _balances;

    //event StakeToken(uint256 tokenAmount, uint256 time, uint256 rewardTime);

    constructor() {
        stakingToken = IERC20(0xE73783024D6436064AA5F2a4d9038da3DB0370AA);
    }

    modifier updateReward(address account) {
        uint256 currentRewardTime = block.timestamp;
        if (block.timestamp > stakeTime[account]) {
            currentRewardTime = stakeTime[account]; // for more than 90 days of staking, we return nothing.
        }
        if (lastRewardTime[account] != 0){
            rewards[account] += (currentRewardTime - lastRewardTime[account]) * _balances[account] * 8 / 1000 / 3600 / 24; //0.8 percent ROI per day
        }
            
        lastRewardTime[account] = currentRewardTime;
        _;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(
            _amount >= 5_000_000_000_000_000,
            "token amount must be bigger than 5000000"
        );
        _balances[msg.sender] += _amount;
        stakeTime[msg.sender] = block.timestamp + 90 days;

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        //emit StakeToken(_amount, block.timestamp, lastRewardTime[msg.sender]);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(
            block.timestamp >= stakeTime[msg.sender],
            "can not withdraw because time is not up"
        );

        uint256 currentBalance = stakingToken.balanceOf(address(this));
        if (currentBalance < _amount) {
            stakingToken.transfer(msg.sender, currentBalance);
            _balances[msg.sender] -= currentBalance;
        } else {
            stakingToken.transfer(msg.sender, _amount);
            _balances[msg.sender] -= _amount;
        }
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        uint256 currentBalance = stakingToken.balanceOf(address(this));
        if (currentBalance < reward) {
            stakingToken.transfer(msg.sender, currentBalance);
        } else {
            stakingToken.transfer(msg.sender, reward);
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}