// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@usernames/library/Helpers.sol";

library PriceFeedConsumer {
    // base = erc20 e.g uniswap
    // quote = eth/usd

    // price derivation method, accepting custom quote
    function getDerivedPrice(address _base, address _quote, int256 amount) public view returns (int256) {
        return _getDerivedPrice(_base, _quote, amount);
    }

    // price derivation method accepting global quote
    function getDerivedPrice(
        mapping(IERC20 => address) storage self,
        IERC20 token,
        address _quote,
        int256 amount
    ) public view returns (int256) {
        return _getDerivedPrice(self[token], _quote, amount);
    }

    // internal method that does the actual derivation
    function _getDerivedPrice(address _base, address _quote, int256 amount) internal view returns (int256) {
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, baseDecimals);

        // since amount is a bigNumber, it automatically converts the expected value to bigint.
        int256 scaledValue = scalePrice(amount, quoteDecimals, baseDecimals);
        return (scaledValue * quotePrice) / basePrice;
    }

    // harmonize differences in quotes decimals
    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) public pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}
