contract C{

function foo() public {
    uint cont = 0;
    uint a = 0;
    uint b = 0;
    if(true){
           cont = a++;
    }else{
        b = b + 1;
        cont = b;
    }

    a = 2;
}

}