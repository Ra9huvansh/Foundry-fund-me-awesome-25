//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

//constant, immutable ----> gas optimization tricks

error FundMe__NotOwner();

//888,027
//864,604
contract FundMe{

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; //5e18 represents $5 as for the price of ETH(from chainlink) in USD, we've taken 18 decimal places.
    // 347 gas - constant
    // 2446 gas - non-constant

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    address private immutable i_owner;
    // immutable - 439 gas
    // not using immutable - 2574 gas

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner{
        //require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender != i_owner){
            revert FundMe__NotOwner();
        }
        _;
    }

    function fund() public payable{
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH"); 
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //resetting the array

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner{

        for(uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //resetting the array

        //transfer
        //msg.sender = address
        //payable(msg.sender) = payable address
        //payable(msg.sender).transfer(address(this).balance);

        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    //What happens if someone sends this contract ETH without calling the fund function or 
    //just call some abstract function which doesn't even exist on the contract 

    //receive()
    receive() external payable{
        fund();
    }
    //fallback()
    fallback() external payable{
        fund();
    }

    /**
     * View/Pure Functions (Getters)
     */

    function getAddressToAmountFunded(address fundingAddress) external view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getOnwer() external view returns(address) {
        return i_owner;
    }
}

// 1. Enums
// 2. Events
// 3. Try / Catch 
// 4. Function Selectors
// 5. abi.encode / decode
// 6. Hashing
// 7. Yul / Assembly
