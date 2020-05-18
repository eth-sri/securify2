contract C{
    function foo() public {
        uint a;
        if(true){
            if(true)
                require(true);
            a = 1;
        }
    
    }
}
