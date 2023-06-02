// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MockV3Aggregator} from "mocks/MocksAndContracts.t.sol";
import {PriceFeedConsumer} from "@usernames/utils/OracleConsumer.sol";
import {ERC20Test, IERC20} from "@usernames/tokens/ERC20.sol";

contract OracleConsumerTest is Test {
    using PriceFeedConsumer for *;

    uint8 public constant BASE_DECIMAL = 9; // link
    int256 public constant BASE_ANSWER = 1e9;

    uint8 public constant QUOTE_DECIMAL = 18; // eth
    int256 public constant QUOTE_ANSWER = 1e18;

    // link/eth == base/quote

    MockV3Aggregator public mockV3AggregatorBase;
    MockV3Aggregator public mockV3AggregatorQuote;

    ERC20Test public testTokenA;
    ERC20Test public testTokenB;

    mapping(IERC20 => address) internal tokenToPriceFeed;

    function setUp() public {
        mockV3AggregatorBase = new MockV3Aggregator(BASE_DECIMAL, BASE_ANSWER);
        mockV3AggregatorQuote = new MockV3Aggregator(QUOTE_DECIMAL, QUOTE_ANSWER);
        testTokenA = new ERC20Test(); // link token
        testTokenB = new ERC20Test(); // eth/usd
        tokenToPriceFeed[testTokenA] = address(mockV3AggregatorBase);
        tokenToPriceFeed[testTokenB] = address(mockV3AggregatorQuote);
    }

    function testConsumerDerivesPrice() public {
        // 0.1^18 eth == 0.1^9 link (1:1)
        int256 price = address(mockV3AggregatorBase).getDerivedPrice(
            address(mockV3AggregatorQuote),
            .1e18
        );
        assertTrue(price == 1e8);
    }

    function testConsumerDerivesPriceGlobal() public {
        int256 price = tokenToPriceFeed.getDerivedPrice(
            testTokenA,
            tokenToPriceFeed[testTokenB],
            .1e18
        );
        assertTrue(price == 1e8);
    }

    function testConsumerScalesPriceToHigherDecimal() public {
        int256 price = 1e9._scalePrice(9, 6);
        assertEq(price, 1e6);
    }

    function testConsumerScalesPriceToLowerDecimal() public {
        int256 price = 1e9._scalePrice(6, 9);
        assertEq(price, 1e12);
    }
}
