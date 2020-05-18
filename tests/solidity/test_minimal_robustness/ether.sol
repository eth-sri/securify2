contract C{
    function transfer(uint a) public payable returns (bool){
        return true;
    }

}

contract B{
    C a;
    function foo() public payable{
        a.transfer(1);
    }
}

contract D{
    function foo() public payable{
        C a;
        a.transfer(1);
    }
}

contract E{
    function foo() public payable{
        C a;
        a.transfer.value(1 ether)(1);
    }
}
