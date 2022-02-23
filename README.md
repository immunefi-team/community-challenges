

* All the writeups can be found under `/writeups` directory.  
* All the poc scripts can be found under `/pocs` directory.

```shell
npm i
for i in pocs/*.js; do npx hardhat run $i; done
```

----

#### Challenges Information

| No | Contracts 	| Type  	| Difficulty 	|   Writeup published	| POC published      	| Discord conversation |
| ---- |--------	|-------	|------------	|---	|--------------------	|- |
| 1 | [vulnerable/Exchange.sol](contracts/vulnerable/Exchange.sol),<br/>[tokens/StokenERC20.sol](contracts/tokens/StokenERC20.sol)      	| ERC20 (handling transfer) 	| Easy       	|   ✅	| ✅ 	| [link](https://discord.com/channels/787092485969150012/803395442578161756/936599859757187083) |
| 2 | [vulnerable/Staking.sol](contracts/vulnerable/Staking.sol),<br/>[tokens/MockERC223.sol](contracts/tokens/MockERC223.sol)   	|   Reentrancy (CEI pattern) 	|    Easy        	|   ✅	|   ✅                  	| [link](https://discord.com/channels/787092485969150012/803395442578161756/937672123521048606) |
| 3  | [vulnerable/Takeover.sol](contracts/vulnerable/Takeover.sol)  | Logical | Easy | ✅ | ✅ | [link](https://discord.com/channels/787092485969150012/803395442578161756/943136588798496790) |
| 4 | [vulnerable/Auction.sol](contracts/vulnerable/Auction.sol),<br/>[tokens/MockERC721.sol](contracts/tokens/MockERC721.sol)      	| Logical (Push vs Pull pattern) 	|   Easy     	|  ✅  	|  ✅	| [link](https://discord.com/channels/787092485969150012/803395442578161756/943874635576016976) |
| 5 | [vulnerable/Staking2.sol](contracts/vulnerable/Staking2.sol),<br/>[tokens/ExpensiveToken.sol](contracts/tokens/ExpensiveToken.sol),<br/>[tokens/MockERC777.sol](contracts/tokens/MockERC777.sol) | | Hard | | | [link](https://discord.com/channels/787092485969150012/803395442578161756/946058230625349642) |
