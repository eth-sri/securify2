contract C{
    function foo1(uint x) public returns (uint){
        return x;
    }

    function foo2(uint x) public returns (uint) {
        return x;
    }

    function bar() public {
        uint a;
        a = foo1(1);
        a = foo1(2);
    }
}
