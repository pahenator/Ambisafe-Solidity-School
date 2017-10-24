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
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
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
        if (lendings[msg.sender].exists) {
            if (lendings[msg.sender].amount + amount > limit) {
                revert();
            } else {
                lendings[msg.sender].amount += amount;
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
         if (!lendings[msg.sender].exists || msg.sender != owner) revert();
         
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