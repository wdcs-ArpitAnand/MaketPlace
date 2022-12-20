// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;



contract holder{
    receive() external payable {}

}

contract sender{
    // holder h = new holder();
    event d(holder);
    function send() public payable{
        holder h = new holder();
        payable(h).transfer(msg.value);
        emit d(h);
        // return h;
    }

    function contractBalance(address contrAdd) public view returns(uint){
        return contrAdd.balance;
    }  
}