//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    address USER = makeAddr("user");

    function setUp() external {
        //us -> FundMeTest -> FundMe
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOnwer(), msg.sender);
    }

    // What can we do to work with addresses outside our system?
    // 1. Unit 
    //    - Testing a specific part of our code 
    // 2. Integration
    //    - Testing how our code works with other parts of our code 
    // 3. Forked
    //    - Testing our code on a simulated real environment
    // 4. Staging
    //    - Testing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey, the next line should revert!
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next Tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunder = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunder, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOnwer());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOnwer().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFounders = 10;
        uint160 startingFounderIndex = 1;
        for(uint160 i = startingFounderIndex; i < numberOfFounders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOnwerBalance = fundMe.getOnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act 
        vm.startPrank(fundMe.getOnwer());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert 
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOnwerBalance == fundMe.getOnwer().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFounders = 10;
        uint160 startingFounderIndex = 1;
        for(uint160 i = startingFounderIndex; i < numberOfFounders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOnwerBalance = fundMe.getOnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act 
        vm.startPrank(fundMe.getOnwer());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert 
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOnwerBalance == fundMe.getOnwer().balance);
    }
} 