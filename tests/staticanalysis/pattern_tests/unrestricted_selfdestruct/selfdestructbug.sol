//pragma solidity ^0.5.0;

// the contract is vulnerable
// the output of your analyzer should be Tainted
contract Contract {
  function foo(uint x) public {
    if(x < 5) {                          // not a guard
      selfdestruct(msg.sender);          // vulnerable
    } else {
      require(msg.sender == address(0xDEADBEEF)); // guard
      selfdestruct(msg.sender);                   // safe
    }
  }
}
