

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
| 3  |       | TODO |
