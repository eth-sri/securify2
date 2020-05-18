contract C{
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;
    address token;

    function foo() public {
    (bool didSucceed, bytes memory resultData) = token.staticcall(bytes("msg"));
    }
}