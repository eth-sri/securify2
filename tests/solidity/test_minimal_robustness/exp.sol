/**
 *Submitted for verification at Etherscan.io on 2020-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2020-01-09
*/

pragma solidity ^0.5.0;

library Decimal {
    struct D256 {
        uint256 value;
    }
}

contract TestStructs {
	constructor() public { 
        Decimal.D256 memory a; 
        a = Decimal.D256(111);
    }
}
