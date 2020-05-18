contract B{

    function bar() public returns (uint, uint){
        return (1,2);
    }

    function foo() public {
        uint a;
        uint256[] memory b;
        (a,b) = abi.decode(msg.data, (uint, uint256[])) ;
        //a = abi.decode(msg.data, (uint)) ;
        //(a,b) = (1,2);
        //(a,b) = bar();
    }
}
