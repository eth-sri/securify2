contract B{
    struct S{
        uint a;
        uint b;
    }
    function bar() public returns (uint, uint, uint){
       return (1,2,3);
    }

    function foo() public {
        S memory s;
        (s.a,, s.b) = bar();
    }
}
