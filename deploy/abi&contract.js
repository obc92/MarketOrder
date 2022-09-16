const { ethers, network } = require("hardhat")
const fs = require("fs")
const { getContractAddress } = require("ethers/lib/utils")
//const { frontEndContractsFile, frontEndAbiFile } = require("../helper-hardhat-config")

const FRONT_END_ADDRESSES_FILE = "../1.uniswapv3-front/constants/contractAddresses.json"
const FRONT_END_ABI_FILE = "../1.uniswapv3-front/constants/abi.json"


module.exports = async function (){
    if (process.env.UPDATE_FRONT_END) {
        console.log("Updating front end...")
        updateContractAddresses()
        updateAbi()
        console.log("Front end written!")
    }
}

async function updateAbi() {
    const MarketOrder = await ethers.getContract("MarketOrder")
    fs.writeFileSync(FRONT_END_ABI_FILE, MarketOrder.interface.format(ethers.utils.FormatTypes.json))//reescriu el arxiu
}

async function updateContractAddresses() {
    const MarketOrder = await ethers.getContract("MarketOrder")
    // const ChainId = network.ChainId//.toString()
    const { getChainId } = hre
    const ChainId = await getChainId()
    const currentAddresses = JSON.parse(fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8"))//LLegeix el file
    if (ChainId in currentAddresses){
        if (!currentAddresses[ChainId].includes(MarketOrder.address)){// Si no inclou la adreça del contract 
            currentAddresses[ChainId].push(MarketOrder.address) // actualitza la adreça en la variable
        }
    }{
        currentAddresses[ChainId] = [MarketOrder.address] //si no existeix afegeis una adreça ja  
    }
    fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddresses))//reescriu el arxiu
    console.log("NewContract:", MarketOrder)
}

module.exports.tags = ["all", "frontend"]