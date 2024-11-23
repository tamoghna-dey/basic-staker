staking.sol :
- the contract contains core logic and stores the tokens send to it for a particular time 
- user can deposit only usdc
- minimum deposit amount is 2 tokens
- the funds get locked for minimum 1 minute, after which the user can choose to withdraw or keep it longer.
- rate of interest is 0.03% per second 
- the protocol takes a fixed fee of 0.005% on the total amount after staking. 
- stake function starts the staking process
- un-stake function un-stakes it and checks if the minimum duration passed or not 
- then after a delay of 2 minutes the user is able to withdraw using withdraw function 

## emiting event also modifies the state 