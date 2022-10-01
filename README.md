# UniswapV3

This code allows you to send ETH to smart contract and place an automatic Stop Loss that sells the position inta an AMM in UniswapV3 with ETH/USDC pair.
The code is implemented in the Goerli testnet

# MarketOrder

Goerli scan:  https://goerli.etherscan.io/

To keep in mind:

There is no restriction on the SL value, if the value is set above the Eth value the position will be inmediatelly sold.
UniswapV3 pools on Goerli testnet does not repressent the same values as the mainnet so ETH/USDC pool could have a 1ETH = 200$ value and change to a complete different value the next hour. 

Once ETH is sent to the contract and SL is set, the contract will work automatically selling the position once the SL is reached and sending the USDC amount to your wallet address.
Multiple wallets can be registered using this contract

# Interact with the contract

Contract: 0xbc8f6a769e27133c524Fb9d817Fb58b82fb52d80

Add on your MM USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

Faucets de Goerli:
https://goerlifaucet.com/
https://faucets.chain.link/

FUNCTIONS:

##Write Contract##

1.Deposit --Deposit ETh quanitty and set SL
Quantitat uint256: 1000000000000000000 (1ETH)
StopLoss (Dollar amount): 1250 

4.Withdraw --Withdraw all your ETH diposited to your wallet 

3.SetStop --Modify the SL previously especified 
SL: 1240

##Read Contract##

2.CallQuantity --Visualize your ETH diposited in the contract
address: 0xCFF..

3.CallStop --Visualize your SL 
address: 0xCFF..

4.EtherPrice --Visualize the ETH value provided by the ChainLink PriceFeed


