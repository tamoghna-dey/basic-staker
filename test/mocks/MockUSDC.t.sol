// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "../../openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {
        // Mint an initial supply to the deployer for testing purposes
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6; // USDC has 6 decimals
    }
}
