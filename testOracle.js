var ethers = require("ethers")

// example assumes that the ethers library has been imported and is accessible within your scope
const getEthUsdtPrice = async () => {
    ////for ethers version 6.0
    const provider = new ethers.JsonRpcProvider("https://data-seed-prebsc-1-s1.binance.org:8545/")
    ////for ethers version <= 5.7.2
    //const provider = new ethers.providers.JsonRpcProvider('https://data-seed-prebsc-1-s1.binance.org:8545/')

    const abi = [
        {
            inputs: [{internalType: "string", name: "marketPair", type: "string"}],
            name: "checkPrice",
            outputs: [
                {internalType: "int256", name: "price", type: "int256"},
                {internalType: "uint256", name: "timestamp", type: "uint256"},
            ],
            stateMutability: "view",
            type: "function",
        },
    ]
    const address = "0xA75e54E618aDC67B205aAC7133fA338d2B9d37Ff"
    const sValueFeed = new ethers.Contract(address, abi, provider)
    const price = (await sValueFeed.checkPrice("eth_usdt")).price

    console.log(`The price is: ${price.toString()}`)
}

getEthUsdtPrice()
