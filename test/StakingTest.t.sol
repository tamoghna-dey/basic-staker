// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "./mocks/MockUSDC.t.sol";
import {IERC20} from "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingTest is Test {
    Staking staking;
    MockUSDC mockUSDC;
    address user;

    function setUp() public {
        // Deploy the MockUSDC token
        mockUSDC = new MockUSDC();

        // Deploy the Staking contract with MockUSDC address
        staking = new Staking(address(mockUSDC));

        // Assign user address and provide it with initial mUSDC balance
        user = address(0x1);
        mockUSDC.transfer(user, 1000 * 10 ** 6); // 1000 mUSDC
        mockUSDC.transfer(address(staking), 10_000 * 10 * 6); //10,000 mUSDC
        console.log("Staking contract balance mUSD:", IERC20(address(mockUSDC)).balanceOf(address(staking)));
        mockUSDC.approve(address(staking), 1000 * 10 ** 6);

        // Label addresses for better readability in test output
        vm.label(user, "User");
        vm.label(address(staking), "StakingContract");
        vm.label(address(mockUSDC), "MockUSDC");
    }

    function testDeposit() public {
        // Set up: User approves staking contract to spend their mUSDC
        vm.startPrank(user);
        mockUSDC.approve(address(staking), 500 * 10 ** 6);

        // Call the deposit function in staking contract
        staking.deposit(500 * 10 ** 6, address(mockUSDC));
        vm.stopPrank();

        // Check if the deposit amount is recorded correctly
        uint256 depositBalance = staking.depositAmountToUser(user);
        assertEq(depositBalance, 500 * 10 ** 6, "Deposit amount mismatch");
    }

    function testStake() public {
        // Prank user to perform deposit and stake
        vm.startPrank(user);

        // Deposit 500 mUSDC first
        mockUSDC.approve(address(staking), 500 * 10 ** 6);
        staking.deposit(500 * 10 ** 6, address(mockUSDC));

        // Stake 500 mUSDC
        staking.stake(500 * 10 ** 6);
        vm.stopPrank();

        // Check that the staked amount is recorded correctly
        uint256 stakedBalance = staking.stakedAmountToUser(user);
        assertEq(stakedBalance, 500 * 10 ** 6, "Stake amount mismatch");
    }

    function testUnstake() public {
        // Prank user to perform deposit, stake, and unstake
        vm.startPrank(user);

        // Deposit and Stake 500 mUSDC
        mockUSDC.approve(address(staking), 500 * 10 ** 6);
        staking.deposit(500 * 10 ** 6, address(mockUSDC));
        staking.stake(500 * 10 ** 6);

        // Simulate time passage to meet minimum lock duration
        vm.warp(block.timestamp + 240); // Advance time by 60 seconds

        // Unstake 500 mUSDC
        staking.unstake(500 * 10 ** 6);
        vm.stopPrank();

        // Check that the unstaked amount is recorded correctly
        uint256 unstakedBalance = staking.unstakeAmountToUser(user);
        assertEq(unstakedBalance, 500 * 10 ** 6, "Unstake amount mismatch");
    }

    function testWithdraw() public {
        vm.startPrank(user);

        mockUSDC.approve(address(staking), 500 * 10 ** 6);
        staking.deposit(500 * 10 ** 6, address(mockUSDC));

        staking.stake(500 * 10 ** 6);

        vm.warp(block.timestamp + 240); 
        staking.unstake(500 * 10 ** 6);
        vm.warp(block.timestamp + 360); 

        staking.withdraw(500 * 10 ** 6);

        vm.stopPrank();

        uint256 finalUnstakedBalance = staking.unstakeAmountToUser(user);
        assertEq(finalUnstakedBalance, 0, "Withdraw amount mismatch");
    }
}
