// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // PriceFeed contract imported from chainlink github

library TokenPrice {
    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);// Retorna 8 decimals
    }

    function ConversionToEth(uint256 DollaAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 Price = getLatestPrice(priceFeed);
        uint256 EthAmount = (DollaAmount * 100000000000)/Price;
        return EthAmount;
    }
}