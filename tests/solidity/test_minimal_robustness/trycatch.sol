interface T{
    function foo() external returns (uint v);
}

contract A{
    function foo() public{
        uint a;
        T ad = T(0);
        try ad.foo() returns (uint v){
            a +=1;
         }catch(bytes memory){
            a= 2;
        }catch Error(string memory){
            a= 3;
        }
        a = 4;

    }
}
