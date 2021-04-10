// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract _TreeCoin{
    int balance;
    
    constructor() {
        balance = 0;
    }
    
    function getBalance() view public returns(int){
        return balance;
    }
    
    function depositBalance(int amount) public{
        balance = balance + amount;
    }
        
    function withdrawBalance(int amount) public{
        balance = balance - amount;
    }
}