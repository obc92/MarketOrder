// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // Keepers import
import "./TokenPrice.sol";

error Quantity_zero();
error Wallet_error();
error Order__UpkeepNotNeeded(uint256 currentBalance, uint256 PlayersNum);

contract MarketOrder is KeeperCompatibleInterface {
    using TokenPrice for uint256; //library

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



    constructor ( address priceFeedAddress) {
        i_owner = msg.sender;
        s_AddressFeed = priceFeedAddress;
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
//----------------------------------------------------------------------------------------
    // function checkUpkeep(bytes memory /* checkData */) public view override returns (//,bytes memory value
    //     bool upkeepNeeded, 
    //     bytes memory num
    //     ){

    //     uint256 EthPrice = 0;
    //     // uint256 i = 2;
    //     EthPrice = getPrice();
    //     num = abi.encodePacked(EthPrice);
    //     // address addr = s_Wallets[0];
    //     if (EthPrice <= 2000){
    //         upkeepNeeded = true;
    //     }

    //     return (upkeepNeeded, num);//, value
    // }

    // function performUpkeep(bytes calldata num) external override {//, bytes calldata value
    //     (bool upkeepNeeded, ) = checkUpkeep("");
        
    //     if (!upkeepNeeded) {
    //         revert Order__UpkeepNotNeeded(
    //             address(this).balance,
    //             s_Wallets.length
    //         );
    //     }
    //     //Byte conversion to uint
    //     uint256 number;
    //     number = abi.decode(num, (uint256));

    //     // for(uint i=0;i<num.length;i++){
    //     //     number = number + uint(uint8(num[i]))*(2**(8*(num.length-(i+1))));
    //     // }
    //     s_nombre = number;
    // }


//-----------------------------------------------------------------------------------------
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
        
        //Sell Val in UniswapV3
        // ··············
        // ··············

        // RESET DATA FROM WALLET 
        // Reseteja les dades
        Dades storage dades = s_Registre[s_Wallets[number]];
        dades.QuantityETH = 0;
        dades.Stop = 0;
        //Delets wallet from the list
        s_Wallets = Remove(number);
    }
//---------------------------------------------------------------------------------------
    // function Decode() public view returns(uint256) {
    //     return s_nombre;
    // }

    // Public view functions
    // function Numero() public view returns(uint256) {
    //     return s_nombre;
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
    function OutPrice() public view returns (uint256){
        uint256 EthP = getPrice();
        return (EthP);
    }
}