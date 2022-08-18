const { getNamedAccounts, deployments, network, ethers } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config.js")
const { verify } = require("../utils/verify.js")

//const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("2")

module.exports = async function ({ getNameAccounts, deployments }) {

    const {deploy, log } = deployments
    const { deployer }  = await getNamedAccounts()
    const chainId = network.config.chainId

    let vrfCoordinatorV2Address, subscriptionId// Aquestes dues variables shan de recuperar de @chainlink

    // if (developmentChains.includes(network.name)) {//Deploy a la rinkeby
    //     const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
    //     vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
    //     const transactionResponse = await vrfCoordinatorV2Mock.createSubscription()
    //     const transactionReceipt = await transactionResponse.wait(1)
    //     subscriptionId = transactionReceipt.events[0].args.subId
    //     //fund subscription
    //     await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT)
    // }else {//Deploy a hardhat enviorment
    //     vrfCoordinatorV2Address = networkConfig[chainId]["VRFCoordinatorV2Mock"]
    //     subscriptionId = networkConfig[chainId]["subscriptionId"]
    // }

    const priceFeedAddress = networkConfig [chainId]["priceFeedAddress"]
    // const gasLane = networkConfig[chainId]["gasLane"]
    // const callbackGaslimit = networkConfig[chainId]["callbackGaslimit"]
    // const interval = networkConfig[chainId]["interval"]

    const args = [priceFeedAddress]
    const MarketOrder = await deploy("MarketOrder", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(MarketOrder.address, args)
    }
    log("--------------------------------")
}

module.exports.tags = ["all", "MarketOrder"] 