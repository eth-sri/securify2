contract C{
    function foo(uint a) public{
        if(a > 0) 
            return;
        a = a + 1;
        revert();
    }

    function bar() public{
        uint x = 4;
        foo(x);
    }

}
