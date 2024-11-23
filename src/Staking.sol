// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Staking {
    //constants
    uint256 constant PERCENT_SCALE = 1_000_000;
    uint256 constant PROTOCOL_FEE_0_005 = 50; //0.005%
    uint256 constant RATE_OF_INTEREST_PER_SECOND_0_03 = 300; //0.03%
    uint256 constant MINIMUM_LOCKED_DURATION = 60; //1min
    uint256 constant MINIMUM_DELAY_AFTER_UNSTAKE = 120; //2min
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //taken from etherscan

    address public tokenAddressUSDC;

    //errors
    error AMOUNT_SHOULD_BE_GREATER_THAN_0(uint256 amount);
    error TOKEN_NOT_USDC(address tokenAddr);
    error USER_NOT_FOUND(address addr);
    error USER_IS_NOT_OWNER(address addr);
    error LOCKED_PERIOD_NOT_PASSED(uint256 time);
    error MINIMUM_STAKE_DURATION_NOT_PASSED(uint256 time);

    //events
    event DepositedSuccessfully(address indexed user, uint256 amount);
    event StakedSuccessfully(address indexed user, uint256 amount);
    event UnstakedSuccessfully(address indexed user, uint256 amount);
    event WithdrawSuccessfully(address indexed user, uint256 amount);

    //mapping
    mapping(address => uint256) public depositAmountToUser;
    mapping(address => uint256) public stakedAmountToUser;
    mapping(address => uint256) public unstakeAmountToUser;
    mapping(address => uint256) public timePassedSinceStake;
    mapping(address => uint256) public timePassedSinceUnstaked;

    constructor(address _tokenAddressUSDC) {
        tokenAddressUSDC = _tokenAddressUSDC;
    }
    //public functions

    function deposit(uint256 amount, address tokenAddress) public payable {
        //checks if the amount>0
        require(amount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_0(amount)");
        //checks if the token is USDC
        require(tokenAddress == tokenAddressUSDC, "TOKEN_NOT_USDC(tokenAddress)");
        //deposits selected amount of funds by user to this contract using openzeppelin library
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        //require(sent, "Failed to send USDC");
        //(bool sent, ) = address(this).call{value: msg.value}("");
        //keeps track of who deposited what token in a mapping
        depositAmountToUser[msg.sender] += amount;
        //emits an event
        emit DepositedSuccessfully(msg.sender, amount);
    }

    function stake(uint256 stakedAmount) public {
        //checks if it is greater than 0
        require(stakedAmount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_0(stakedAmount)");
        //user selects the amount of funds they want to stake
        //checks if user has the balance from the mapping
        require(stakedAmount <= depositAmountToUser[msg.sender], "Wrong amount entered");
        //keeps track of time at which funds were deposited
        timePassedSinceStake[msg.sender] = block.timestamp;
        //updates the token deposit mapping token amount for the user
        depositAmountToUser[msg.sender] = depositAmountToUser[msg.sender] - stakedAmount;
        //updates a mapping for staked amount and the addr of the user
        stakedAmountToUser[msg.sender] = stakedAmount;
        //emits an event
        emit StakedSuccessfully(msg.sender, stakedAmount);
    }

    function unstake(uint256 unstakedAmount) public {
        //user selects amount of funds to be unstaked
        //checks amount>0
        require(unstakedAmount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_0(unstakedAmount)");
        //checks if the user is the owner of the funds from mapping
        require(unstakedAmount <= stakedAmountToUser[msg.sender], "wrong amount entered");
        //checks if the minimum duration for staking is passed or not
        require(
            block.timestamp > timePassedSinceStake[msg.sender] + MINIMUM_LOCKED_DURATION,
            "MINIMUM_STAKE_DURATION_NOT_PASSED(timePassedSinceStake[msg.sender]"
        );
        //keeps track of time at which unstaked was called
        timePassedSinceUnstaked[msg.sender] = block.timestamp;
        //updates the mapping for staked
        stakedAmountToUser[msg.sender] = stakedAmountToUser[msg.sender] - unstakedAmount;
        //keeps track of unstaked funds for the particular user in another mapping
        unstakeAmountToUser[msg.sender] = unstakedAmount;
        //emits an event
        emit UnstakedSuccessfully(msg.sender, unstakedAmount);
    }

    function withdraw(uint256 withdrawAmount) public {
        //checks amount>0
        require(withdrawAmount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_0(withdrawAmount)");
        //checks if delay period has passed or not
        require(
            block.timestamp > timePassedSinceUnstaked[msg.sender] + MINIMUM_DELAY_AFTER_UNSTAKE,
            "LOCKED_PERIOD_NOT_PASSED(timePassedSinceUnstaked[msg.sender]"
        );
        //checks if the user is owner of the funds
        require(withdrawAmount <= unstakeAmountToUser[msg.sender], "wrong amount entered");
        //calculates rewards
        uint256 elapsedTime = block.timestamp - timePassedSinceStake[msg.sender];
        uint256 rewardAmount = (withdrawAmount * elapsedTime * RATE_OF_INTEREST_PER_SECOND_0_03) / PERCENT_SCALE;
        //calculates fees;
        uint256 protocolFees = (rewardAmount * PROTOCOL_FEE_0_005) / PERCENT_SCALE;
        //transfers the funds back to the user after deducting the fees
        uint256 finalAmount = withdrawAmount + rewardAmount - protocolFees;
        //(bool sent, ) = msg.sender.call{value: finalAmount}("");
        //require(sent, "Failed to send USDC");
        //updates the unstaked mapping
        unstakeAmountToUser[msg.sender] -= withdrawAmount;
        IERC20(tokenAddressUSDC).transfer(msg.sender, finalAmount);
        //emits an event
        emit WithdrawSuccessfully(msg.sender, finalAmount);
    }
}
