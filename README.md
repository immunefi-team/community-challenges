

* All the writeups can be found under `/writeups` directory.  
* All the poc scripts can be found under `/pocs` directory.

```shell
npm i
for i in pocs/*.js; do npx hardhat run $i; done
```

----

#### Challenges Information


| No | Contracts 	| Type  	| Difficulty 	|   Writeup published	| POC published      	|
| ---- |--------	|-------	|------------	|---	|--------------------	|
| 1 | [vulnerable/Exchange.sol](contracts/vulnerable/Exchange.sol),<br/>[tokens/StokenERC20.sol](contracts/tokens/StokenERC20.sol)      	| ERC20 (handling transfer) 	| Easy       	|   ✅	| ✅ 	|
| 2 | [vulnerable/Staking.sol](contracts/vulnerable/Staking.sol),<br/>[tokens/MockERC223.sol](contracts/tokens/MockERC223.sol)   	|   Reentrancy	|    Easy        	|   ✅	|   ✅                  	|
| 3  | [vulnerable/Takeover.sol](contracts/vulnerable/Takeover.sol)  | Logical | Easy | ✅ | ✅ |
| 4 | [vulnerable/Auction.sol](contracts/vulnerable/Auction.sol),<br/>[tokens/MockERC721.sol](contracts/tokens/MockERC721.sol)      	|  	|        	|   	|  	|
| 5 | [vulnerable/Staking2.sol](contracts/vulnerable/Staking2.sol),<br/>[tokens/ExpensiveToken.sol](contracts/tokens/ExpensiveToken.sol),<br/>[tokens/MockERC777.sol](contracts/tokens/MockERC777.sol) | | Hard | [Discord conversation](https://discord.com/channels/787092485969150012/803395442578161756/946058230625349642) | |
