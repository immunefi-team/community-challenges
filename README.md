

* All the writeups can be found under `/writeups` directory.  
* All the poc scripts can be found under `/pocs` directory.

```shell
npm i
for i in pocs/*.js; do npx hardhat run $i; done
```



----

#### Challenges Information


| Contracts 	| Type  	| Difficulty 	|   Writeup published	| POC published      	|
|--------	|-------	|------------	|---	|--------------------	|
| Exchange.sol,StokenERC20.sol      	| ERC20 (handling transfer) 	| Easy       	|   ✅	| ✅ 	|
| Staking.sol,MockERC223.sol     	|   ⌛	|    Easy        	|   ⌛	|   ⌛                  	|
