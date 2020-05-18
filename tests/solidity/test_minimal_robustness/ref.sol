interface T{
    function foo() external returns (uint v);
}

contract A{
    function foo() public{
        uint a = 1;
        if (a == 1){
            a = 2;
        }else{
            a =3;
        }
    }
}
