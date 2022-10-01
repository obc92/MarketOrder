const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts, provider } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config.js")
// import { Pool } from '@uniswap/v3-sdk'
const {Pool} = require("@uniswap/v3-sdk")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("MarketOrder Unit Tests", async function () {
          let MarketOrder //, raffleContract, vrfCoordinatorV2Mock, raffleEntranceFee, interval, player // , deployer
          const chainId = network.config.chainId
          const Value1 = ethers.utils.parseEther("5") //ethers.utils.parseEther("0.3")
          const Value2 = ethers.utils.parseEther("10")
          const Value3 = ethers.utils.parseEther("20")
          const ArrayValue = [Value1, Value2, Value3]
          const ArraySL = [3100, 2000, 1160]

          // let owner
          // let addr1
          // let addr2

          beforeEach(async function () {
            const {deployer} = await getNamedAccounts()
            const {second} = await getNamedAccounts()
            //console.log(`second: ${second}`)
            const {third} = await getNamedAccounts()
            const {forth} = await getNamedAccounts()
            accounts = await ethers.getSigners()
            // const [owner, addr1, addr2] = await ethers.getSigners()
            // console.log(`Accounts: ${addr1}`)
            await deployments.fixture(["all"])
            MarketOrder = await ethers.getContract("MarketOrder", deployer)
            //mockV3Aggregator = await ethers.getContract("MockV3Aggregator", deployer)
          })
          // describe("Constructor", async function () {
          //     it("Intitiallizes the MarketOrder correctly with the right price feed", async function () {
          //         const PriceFeed = await MarketOrder.ActualFeed()
          //         assert.equal(PriceFeed.toString(), "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e")//Sha de cumplir la condicio perque el test doni OK
          //     })
          //   })
          describe("Subscription", async function () {//PriceConversion
            it("Error when sending 0 value", async function () {
              await expect(MarketOrder.Deposit(1750, { value: ethers.utils.parseEther("0")})).to.be.revertedWith("Quantity_zero")
              // const Value1 = ethers.utils.parseEther("5")
              // console.log(`Value1: ${Value1}`)
            })
            it("Subscribes the deployer and checks data", async function () {
              const {deployer} = await getNamedAccounts()
              const stop = 1750
              const Value = { value: Value1 }
              await MarketOrder.Deposit(stop, Value)

              const Quantity = await MarketOrder.CallQuantity(deployer)
              console.log(`Q: ${Quantity}`)
              const Stop = await MarketOrder.CallStop(deployer)
              console.log(`S: ${Stop}`)
              assert.equal(Quantity.toString(), ethers.utils.parseEther("5"))
              assert.equal(Stop.toString(), 1750)

            })
            it("Checks contract balance", async function () {
              await MarketOrder.Deposit(1750, { value: ethers.utils.parseEther("5")})

              const Balance = await MarketOrder.getBalance()
              assert.equal(Balance.toString(), Value1) 
              console.log(`Balance: ${Balance}`)
            })    

            it("Subscribes multiple deployers", async function () {
              const {deployer} = await getNamedAccounts()
              const {second} = await getNamedAccounts()
              const {third} = await getNamedAccounts()
              Acc = [deployer, second, third]
              console.log(deployer)
              const additionalEntrances = 3
              const startingIndex = 0
              const accounts = await ethers.getSigners()
              for (let i = startingIndex; i < startingIndex + additionalEntrances; i++) {
                MarketOrder = MarketOrder.connect(accounts[i])
                await MarketOrder.Deposit(ArraySL[i], { value: ArrayValue[i] })
                console.log(`Account: ${accounts[i].address}  Value: ${ArrayValue[i]} SL: ${ArraySL[i]}`)                
              }
              // const Address = MarketOrder.getMembers()
              // Address.then(data => {
              //   console.log(data)
              //   process.exit();
              // })
              for (let i = 0; i < 3; i++) {
                const Quantity = await MarketOrder.CallQuantity(accounts[i].address)
                console.log(`Q: ${Quantity}`)
                const Stop = await MarketOrder.CallStop(accounts[i].address)
                console.log(`S: ${Stop}`)
                assert.equal(Quantity.toString(), ArrayValue[i])
                assert.equal(Stop.toString(), ArraySL[i])
              }
            })   
          })
          describe("Withdraw Function", async function () {
              it("Fa Withdraw el deployer", async function () {
                const {deployer} = await getNamedAccounts()
                const stop = 1750
                const Value = { value: Value1 }
                await MarketOrder.Deposit(stop, Value)

                const QuantityInicial = await MarketOrder.CallQuantity(deployer)
                console.log(`Quantity: ${QuantityInicial}`)
                const StopInicial = await MarketOrder.CallStop(deployer)
                console.log(`Stop: ${StopInicial}`)

                const Balance = await MarketOrder.getBalance()
                console.log(`BalanceInici: ${Balance}`)

                await MarketOrder.Withdraw()
                const FinalBalance = await MarketOrder.getBalance()
                console.log(`FinalBalance: ${FinalBalance}`)
                assert.equal(FinalBalance.toString(), "0")

                //Torna a inscriure per veure si es lia el mapping 
                // const a = 1150
                // const b = { value: Value1 }
                // await MarketOrder.Deposit(a, b)

                //Shan borrat les dades al fer W corrctament
                const Quantity = await MarketOrder.CallQuantity(deployer)
                console.log(`Deleted Quantity: ${Quantity}`)
                const Stop = await MarketOrder.CallStop(deployer)
                console.log(`Deleted Stop: ${Stop}`)

                // Al intentar tornar a treure calers no deixa ja que sha borrat la wallet
                await expect(MarketOrder.Withdraw()).to.be.revertedWith("Wallet_error()")

                // La wallet sha borrat del array correctament
                const Address = MarketOrder.getMembers()
                Address.then(data => {
                  console.log(data)
                  //process.exit();
                })

              })
              it("Don't allow rug", async function () {
                const stop = 1750
                const Value = { value: Value1 }
                await MarketOrder.Deposit(stop, Value)
                const accounts = await ethers.getSigners()
                // const Rugger = accounts[4]
                MarketOrder = MarketOrder.connect(accounts[3])
                console.log(`Rugger: ${accounts[3].address}`)

                // await MarketOrder.Withdraw()
                // const FinalBalance = await MarketOrder.getBalance()
                await expect(MarketOrder.Withdraw()).to.be.revertedWith("Wallet_error()")
                // assert.equal(FinalBalance.toString(), "5000000000000000000")          
                
                const Address = MarketOrder.getMembers()
                Address.then(data => {
                  console.log(data)
                  //process.exit();
                })

              })
              it("Withdraw one by one", async function () {
                
                const additionalEntrances = 3
                const startingIndex = 0
                const accounts = await ethers.getSigners()
                // console.log(`AA ${accounts.address}`) 
                for (let i = startingIndex; i < startingIndex + additionalEntrances; i++) {
                  MarketOrder = MarketOrder.connect(accounts[i])
                  await MarketOrder.Deposit(ArraySL[i], { value: ArrayValue[i] })
                  console.log(`Account: ${accounts[i].address}  Value: ${ArrayValue[i]} SL: ${ArraySL[i]}`)                
                }
                for (let i = 0; i < 3; i++) {
                  // console.log(`AA ${accounts[i].address}`)
                  MarketOrder = MarketOrder.connect(accounts[i])
                  const Quantity = await MarketOrder.CallQuantity(accounts[i].address)
                  console.log(`Quantity: ${Quantity}`)
                  const Stop = await MarketOrder.CallStop(accounts[i].address)
                  console.log(`Stop: ${Stop}`)
                  assert.equal(Quantity.toString(), ArrayValue[i])
                  assert.equal(Stop.toString(), ArraySL[i])
                }

                for (let i = 0; i < 3; i++){
                  const AddressOut = MarketOrder.getMembers()
                  AddressOut.then(data => {
                  console.log(data)
                  })
                  console.log(`NewBalance: ${await MarketOrder.getBalance()}`)
                  MarketOrder = MarketOrder.connect(accounts[i])
                  await MarketOrder.Withdraw()
                }

                const AddressOut = MarketOrder.getMembers()
                AddressOut.then(data => {
                  console.log(data)
                })
              })
            describe("Testing Upkeepers ... ", async function () {
              it("Check Keepers", async function () {
                
                const additionalEntrances = 3
                const startingIndex = 0
                const accounts = await ethers.getSigners()
                // console.log(`AA ${accounts.address}`) 
                for (let i = startingIndex; i < startingIndex + additionalEntrances; i++) {
                  MarketOrder = MarketOrder.connect(accounts[i])
                  await MarketOrder.Deposit(ArraySL[i], { value: ArrayValue[i] })
                  console.log(`Account: ${accounts[i].address}  Value: ${ArrayValue[i]} SL: ${ArraySL[i]}`)                
                }

                const AddressOut = MarketOrder.getMembers()
                AddressOut.then(data => {
                  console.log(data)
                })

                //await MarketOrder.performUpkeep([])
                const [condition] = await MarketOrder.checkUpkeep([])
                const { upkeepNeeded } = await MarketOrder.callStatic.checkUpkeep("0x")
                const { num } = await MarketOrder.callStatic.checkUpkeep("0x")
                console.log(`condition: ${condition} nombre: ${num} upkeepNeeded: ${upkeepNeeded}`)
                const EthV = await MarketOrder.OutPrice()
                console.log(`EthV: ${EthV}`)
                await network.provider.request({ method: "evm_mine", params: [] })

                

                await MarketOrder.performUpkeep([])
                const { number } = await MarketOrder.callStatic.checkUpkeep("0x")
                console.log(`number: ${number}`)
                // await network.provider.request({ method: "evm_mine", params: [] })
                //assert.equal(EthV, 1500)


                const Balance = await MarketOrder.getBalance()
                console.log(`Balance: ${Balance}`)
                for (let i = startingIndex; i < startingIndex + additionalEntrances; i++) {
                  MarketOrder = MarketOrder.connect(accounts[i])
                  console.log(`Account: ${accounts[i].address}  Value: ${ArrayValue[i]} SL: ${ArraySL[i]}`)                
                }
                for (let i = 0; i < 3; i++) {
                  // console.log(`AA ${accounts[i].address}`)
                  MarketOrder = MarketOrder.connect(accounts[i])
                  const Quantity = await MarketOrder.CallQuantity(accounts[i].address)
                  console.log(`Quantity: ${Quantity}`)
                  const Stop = await MarketOrder.CallStop(accounts[i].address)
                  console.log(`Stop: ${Stop}`)
                }
                const AddressOut1 = MarketOrder.getMembers()
                AddressOut1.then(data => {
                  console.log(data)
                })
                // const nombre = MarketOrder.Numero()
                // console.log(`nombre: ${nombre}`)
              
              })
            //   describe("Keepers testing ... ", async function () {
            //     it("Calling num", async function () {
                  
            //       const [condition] = await MarketOrder.checkUpkeep([])
            //       const { upkeepNeeded } = await MarketOrder.callStatic.checkUpkeep("0x")
            //       const { num } = await MarketOrder.callStatic.checkUpkeep("0x")
            //       console.log(`condition: ${condition} nombre: ${num} upkeepNeeded: ${upkeepNeeded}`)
            //       await network.provider.request({ method: "evm_mine", params: [] })

            //       await MarketOrder.performUpkeep([])
            // //     const { number } = await MarketOrder.callStatic.checkUpkeep("0x")
            // //     console.log(`number: ${number}`)
            //       // await network.provider.request({ method: "evm_mine", params: [] })
            // //     //assert.equal(EthV, 1500)


            //       const nombre = MarketOrder.Decode()
            //       console.log(`nombre: ${nombre.toString()}`)
            //       assert.equal(nombre.toString(), "2")  


            //       })
                })
            })  
        })

    