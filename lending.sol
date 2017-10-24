pragma solidity ^0.4.11;
contract Lending {
    struct LendingData {
        bool exists;
        address person;
        uint amount;
    }
    
    mapping(address => LendingData) lendings;
    address owner;
    uint limit;
    
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }
    
    event ReturnedPart (address borrower, uint amount);
    event ReturnedAll (address borrower, uint amount);
    event BorrowedMoney (address borrower, uint amount);
    
    function Lending(uint _limit) public {
        owner = msg.sender;
        limit = _limit;
    }
    
    function borrowMoney(uint amount) public{
        if (amount == 0) revert();
        
        if (lendings[msg.sender].exists) {
            if (amount > limit - lendings[msg.sender].amount) {
                revert();
            } else {
                lendings[msg.sender].amount += amount;
                BorrowedMoney(msg.sender, amount);
            }
        } else {
            if (amount <= limit) {
                lendings[msg.sender] = LendingData({exists: true, person: msg.sender, amount: amount});
                BorrowedMoney(msg.sender, amount);
            } else {
                revert();
            }
        }
    }
    
    function returnMoney(uint amount) public onlyBy(owner) {
         if (!lendings[msg.sender].exists) revert();
         
         if (amount < lendings[msg.sender].amount) {
             lendings[msg.sender].amount -= amount;
             ReturnedPart(msg.sender, amount);
         } else {
             lendings[msg.sender].amount = 0;
             ReturnedAll(msg.sender, amount);
         }
    }
    
    function checkAmount() public view returns (uint) {
        if (!lendings[msg.sender].exists) { 
            return 0;
        } else {
            return lendings[msg.sender].amount;
        }
    }
}