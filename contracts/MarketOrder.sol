// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma abicoder v2;//

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';//
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // Keepers import
import "./TokenPrice.sol";

interface IWETH {//
    function approve(address guy, uint wad) external returns (bool);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint amt) external;
    function balanceOf(address own) external returns (uint256);
}

error Quantity_zero();
error Wallet_error();
// error Stop_error();
error Order__UpkeepNotNeeded(uint256 currentBalance, uint256 PlayersNum);

contract MarketOrder is KeeperCompatibleInterface, ERC20  {// 
    using TokenPrice for uint256; //library

    ISwapRouter public immutable swapRouter;//
    AggregatorV3Interface public priceFeed;

    struct Dades {
        uint256 QuantityETH;
        uint256 QuantityUSDC;
        uint256 Stop;
    }

    address payable [] private s_Wallets;
    mapping (address => Dades) s_Registre;
    address public immutable i_owner;
    address public s_AddressFeed;
    uint256 public s_nombre = 0;

    address public constant weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;//0xEEa85fdf0b05D1E0107A61b4b4DB1f345854B952;//0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint24 public constant poolFee = 3000;
    uint256 public UsdOut;

    constructor (ISwapRouter _swapRouter) ERC20("Wrapped Ether", "WETH") {// address priceFeedAddress  ISwapRouter _swapRouter // ERC20("Wrapped Ether", "WETH")
        i_owner = msg.sender;
        swapRouter = _swapRouter;//_swapRouter;
        s_AddressFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;//priceFeedAddress;
        priceFeed = AggregatorV3Interface(s_AddressFeed);//Goerli: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e//Rinkeby:0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        
    }

    modifier onlyOwner{
        require(msg.sender == i_owner);  
        _;     
    }

    function Deposit(uint256 StopLoss) public payable {//Deposita quantity i es registre  uint256 StopLoss  //uint256 StopLoss

        //Pay subscription
        if (msg.value == 0){
            revert Quantity_zero();
        }
        //----- Can't send SL above Eth price -----------
        // uint256 EthVal = getPrice();
        // if (StopLoss < EthVal){
        //     revert Stop_error();
        // }

        //Add wallet to the s_Wallets
        bool listed;
        address[] memory id = new address[](s_Wallets.length);
        for (uint i = 0; i < s_Wallets.length; i++){
            id[i] = s_Wallets[i];
            if (listed = (msg.sender == id[i])) {
                break;
            }
        }
        if (listed == true){
            Dades storage dades = s_Registre[msg.sender];
            dades.QuantityETH += msg.value;
            dades.Stop = StopLoss;
        }
        else {
            s_Wallets.push(payable(msg.sender));
            //Registre dades
            Dades storage dades = s_Registre[msg.sender];
            dades.QuantityETH += msg.value;
            dades.Stop = StopLoss;
        }
        
    } 

    function SetStop(uint256 StopLoss) public {
        bool listed;
        uint256 num;
        address[] memory id = new address[](s_Wallets.length);
        for (uint i = 0; i < s_Wallets.length; i++){
            id[i] = s_Wallets[i];
            if (listed = (msg.sender == id[i])) {
                num = i;
                break;
            }
        }
        //require(listed, 'Wallet not listed');
        if (!listed){
            revert Wallet_error();
        }
        Dades storage dades = s_Registre[msg.sender];
        dades.Stop = StopLoss;
    }

    function Withdraw () public {
        //Sends error if wallet is not registered 
        bool listed;
        uint256 num;
        address[] memory id = new address[](s_Wallets.length);
        for (uint i = 0; i < s_Wallets.length; i++){
            id[i] = s_Wallets[i];
            if (listed = (msg.sender == id[i])) {
                num = i;
                break;
            }
        }
        //require(listed, 'Wallet not listed');
        if (!listed){
            revert Wallet_error();
        }
        //Agafa la quanittat que te per fer el W
        Dades memory Quantity = s_Registre[msg.sender];
        uint256 Value = Quantity.QuantityETH;
        //Executes W
        (bool Success, ) = msg.sender.call{value: Value}("");
        require(Success);
        //Reseteja les dades
        Dades storage dades = s_Registre[msg.sender];
        dades.QuantityETH = 0;
        dades.Stop = 0;
        //Borrar wallet que ha fet W
        s_Wallets = Remove(num);
    }

    function Remove(uint num) internal returns(address payable [] memory) {// Borra la wallet del array borrant la posicio tmb

        for (uint i = num; i < s_Wallets.length - 1; i++){
            s_Wallets[i] = s_Wallets[i+1];
        }
        delete s_Wallets[s_Wallets.length-1];
        s_Wallets.pop();
        return s_Wallets;
    }

    function ModifyFeed(address NewFeed) external onlyOwner {
        s_AddressFeed = NewFeed;
        priceFeed = AggregatorV3Interface(s_AddressFeed);
    }

    //priceFeed
    function getPrice() internal view returns(uint256) { //Function where I call the conversion
       
        uint256 EthPrice = TokenPrice.dolarValue(priceFeed);
        return EthPrice;
    }

//-----------------------------------------------------------------------------------------
    //UniswapV3 & wrapped eth
    function wrap(uint256 SellQ) internal {
        //uint256 Wbal = SellQ;
        IWETH(weth).deposit{value: SellQ}();
        // IERC20(weth).deposit{value: Wbal}();
    }

    function WETHTokenBalance() public view returns(uint) {
        ERC20 token = ERC20(weth); // token is cast as type IERC20, so it's a contract
        return token.balanceOf(address(this));
    }

    // function WETHTokenBalance() internal returns(uint) {
    //     // ERC20 token = ERC20(weth); // token is cast as type IERC20, so it's a contract
    //     // return token.balanceOf(address(this));
    //     uint wethtoken = IWETH(weth).balanceOf(address(this));
    //     return wethtoken;
    // }

    function swapExactInputSingle(uint256 SellQ, address selWallet) internal returns (uint256 amountOut){//uint256 amountIn
    
        wrap(SellQ);
        uint balance = WETHTokenBalance();

        // // Approve the router to spend weth.
        TransferHelper.safeApprove(weth, address(swapRouter), balance);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: weth,
                tokenOut: USDC,
                fee: poolFee,
                recipient: selWallet,
                deadline: block.timestamp,
                amountIn: balance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        // return amountOut;
        UsdOut = amountOut;
        
    }

    //Keepers
    function checkUpkeep(bytes memory /* checkData */) public view override returns (//,bytes memory value
        bool upkeepNeeded, 
        bytes memory num
        ){
        
        bool sellTime; 
        bool Quant;
        uint256 EthPrice;
        // bytes memory Wallet;
        // bytes memory num; 

        EthPrice = getPrice();

        address[] memory id = new address[](s_Wallets.length);

        for (uint i = 0; i < s_Wallets.length; i++) {           //Search in loop which Stop should be triggered
          id[i] = s_Wallets[i];
          Dades memory Data = s_Registre[id[i]];
          uint256 SL = Data.Stop;
          uint256 Q = Data.QuantityETH;
          sellTime = (SL >= EthPrice); 
          Quant = (Q > 0);
          if (sellTime && Quant){
            num = abi.encodePacked(i,Q);
            // Wallet = abi.encode(id[i]);
            //value = abi.encodePacked(Q);
            upkeepNeeded = (sellTime && Quant);
            break;
          }
          //upkeepNeeded = (sellTime && Quant); //All conditions must be True
        }  
        //upkeepNeeded = true;
        return (upkeepNeeded, num);//, value
    }

    function performUpkeep(bytes calldata num) external override {//, bytes calldata value
        (bool upkeepNeeded, ) = checkUpkeep("");
        
        if (!upkeepNeeded) {
            revert Order__UpkeepNotNeeded(
                address(this).balance,
                s_Wallets.length
            );
        }
        //Byte conversion to uint
        uint256 number;
        uint256 SellQ;
        (number, SellQ) = abi.decode(num, (uint256, uint256));
        // number = abi.decode(num, (uint256));
        // number = Decode(num);

        // for(uint i=0;i<num.length;i++){
        //     number = number + uint(uint8(num[i]))*(2**(8*(num.length-(i+1))));
        // }

        // uint256 Val;
        // for(uint i=0;i<value.length;i++){
        //     Val = Val + uint(uint8(value[i]))*(2**(8*(value.length-(i+1))));
        // }
        
        //---------------------Sell Val in UniswapV3------------------------
        address selWallet = s_Wallets[number];
        swapExactInputSingle(SellQ, selWallet);

        // RESET DATA FROM WALLET 
        // Reseteja les dades
        Dades storage dades = s_Registre[s_Wallets[number]];
        dades.QuantityETH = 0;
        dades.Stop = 0;
        //Delets wallet from the list
        s_Wallets = Remove(number);
    }
//----------------------------------- View functions ----------------------------------------------------
    //## View function with the oppenzeppelin contract, solc version not compiling
    // function WETHTokenBalance() public view returns(uint) {
    //     ERC20 token = ERC20(weth); // token is cast as type IERC20, so it's a contract
    //     return token.balanceOf(address(this));
    // }

    // function USDCTokenBalance() public view returns(uint) {
    //     ERC20 token = ERC20(USDC); // token is cast as type IERC20, so it's a contract
    //     return token.balanceOf(msg.sender);
    // }


    function ActualFeed() public view returns(address) {
        return s_AddressFeed;
    }
    function CallQuantity(address add) public view returns (uint256){
        Dades memory data = s_Registre[add];
        if (data.QuantityETH > data.QuantityUSDC){
            return (data.QuantityETH);
        }
        else {
            return (data.QuantityUSDC);
        }
        // return (data.QuantityETH);
    }
    function CallStop(address add) public view returns (uint256){
        Dades memory data = s_Registre[add];
        return (data.Stop);
    }
    function getMembers() public view returns (address[] memory){
      address[] memory id = new address[](s_Wallets.length);
      for (uint i = 0; i < s_Wallets.length; i++) {
          id[i] = s_Wallets[i];
      }
      return id;
    }
    function getBalance() public view returns (uint256){
        return (address(this).balance);
    }
    function EtherPrice() public view returns (uint256){
        uint256 EthP = getPrice();
        return (EthP);
    }
}