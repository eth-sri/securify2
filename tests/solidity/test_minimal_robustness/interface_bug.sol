/**
 *Submitted for verification at Etherscan.io on 2020-03-04
*/

/*
 * Copyright ©️ 2018-2020 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018-2020 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 * 
 * 🌎 Galt Project is an international decentralized land and real estate property registry
 * governed by DAO (Decentralized autonomous organization) and self-governance platform for communities
 * of homeowners on Ethereum.
 * 
 * 🏡 https://galtproject.io
 */

interface IOwnedUpgradeabilityProxy {
  function implementation() external view returns (address);
  function proxyOwner() external view returns (address owner);
  function transferProxyOwnership(address newOwner) external;
  function upgradeTo(address _implementation) external;
  function upgradeToAndCall(address _implementation, bytes calldata _data) external payable;
}

interface UpgradeScript {
    function argsWithSignature() external view returns (bytes memory);
}

contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * Should be implemented in a descendant contract
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address) {
    assert(false);
  }

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}


contract UpgradeabilityProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("io.galtproject.proxy.implementation");

  /**
   * @dev Constructor function
   */
  constructor() public {}

  /**
   * @dev Tells the address of the current implementation
   * @return address of the current implementation
   */
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param newImplementation address representing the new implementation to be set
   */
  function setImplementation(address newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param newImplementation representing the address of the new implementation to be set
   */
  function _upgradeTo(address newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != newImplementation);
    setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }
}

contract OwnedUpgradeabilityProxy is IOwnedUpgradeabilityProxy, UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("io.galtproject.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setUpgradeabilityOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) external onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation) external onlyProxyOwner {
    _upgradeTo(implementation);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
   * to initialize whatever is needed through a low level call.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation, bytes calldata data) payable external onlyProxyOwner {
    _upgradeTo(implementation);
    (bool x,) = address(this).call.value(msg.value)(data);
    require(x);
  }
}

interface IOwnedUpgradeabilityProxyFactory {
  function build() external returns(IOwnedUpgradeabilityProxy);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FundBareFactory {
  address public implementation;
  IOwnedUpgradeabilityProxyFactory internal ownedUpgradeabilityProxyFactory;

  constructor(IOwnedUpgradeabilityProxyFactory _factory, address _impl) public {
    ownedUpgradeabilityProxyFactory = _factory;
    implementation = _impl;
  }

  function build()
    external
    returns (address)
  {
    return _build("initialize(address)", address(this), true, true);
  }

  function build(address _addressArgument, bool _transferOwnership, bool _transferProxyOwnership)
    external
    returns (address)
  {
    return _build("initialize(address)", _addressArgument, _transferOwnership, _transferProxyOwnership);
  }

  function build(string calldata _signature, address _addressArgument, bool _transferOwnership, bool _transferProxyOwnership)
    external
    returns (address)
  {
    return _build(_signature, _addressArgument, _transferOwnership, _transferProxyOwnership);
  }

  function build(bytes calldata _payload, bool _transferOwnership, bool _transferProxyOwnership)
    external
    returns (address)
  {
    return _build(_payload, _transferOwnership, _transferProxyOwnership);
  }

  // INTERNAL

  function _build(string memory _signature, address _addressArgument, bool _transferOwnership, bool _transferProxyOwnership)
    internal
    returns (address)
  {
    return _build(
      abi.encodeWithSignature(_signature, _addressArgument),
      _transferOwnership,
      _transferProxyOwnership
    );
  }

  function _build(bytes memory _payload, bool _transferOwnership, bool _transferProxyOwnership)
    internal
    returns (address)
  {
    IOwnedUpgradeabilityProxy proxy = ownedUpgradeabilityProxyFactory.build();

    proxy.upgradeToAndCall(implementation, _payload);

    if (_transferOwnership == true) {
      Ownable(address(proxy)).transferOwnership(msg.sender);
    }

    if (_transferProxyOwnership == true) {
      proxy.transferProxyOwnership(msg.sender);
    }

    return address(proxy);
  }
}

interface IACL {
  function setRole(bytes32 _role, address _candidate, bool _allow) external;
  function hasRole(address _candidate, bytes32 _role) external view returns (bool);
}

interface IFundRegistry {
  function setContract(bytes32 _key, address _value) external;

  // GETTERS
  function getContract(bytes32 _key) external view returns (address);
  function getGGRAddress() external view returns (address);
  function getPPGRAddress() external view returns (address);
  function getACL() external view returns (IACL);
  function getStorageAddress() external view returns (address);
  function getMultiSigAddress() external view returns (address payable);
  function getRAAddress() external view returns (address);
  function getControllerAddress() external view returns (address);
  function getProposalManagerAddress() external view returns (address);
}

contract Initializable {

  /**
   * @dev Indicates if the contract has been initialized.
   */
  bool public initialized;

  /**
   * @dev Modifier to use in the initialization function of a contract.
   */
  modifier isInitializer() {
    require(!initialized, "Contract instance has already been initialized");
    _;
    initialized = true;
  }
}

contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        external
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }


    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

contract FundMultiSig is MultiSigWallet, Initializable {
  event NewOwnerSet(uint256 required, uint256 total);

  bytes32 public constant ROLE_OWNER_MANAGER = bytes32("owner_manager");
  address public constant ETH_CONTRACT_ADDRESS = address(1);

  IFundRegistry public fundRegistry;

  constructor(
    address[] memory _owners
  )
    public
    // WARNING: the implementation won't use this constructor data anyway
    MultiSigWallet(_owners, 1)
  {
  }

  function initialize(
    address[] calldata _owners,
    uint256 _required,
    address _fundRegistry
  )
    external
    isInitializer
    validRequirement(_owners.length, _required)
  {
    // solium-disable-next-line operator-whitespace
    for (uint i=0; i<_owners.length; i++) {
      // solium-disable-next-line error-reason
      require(!isOwner[_owners[i]] && _owners[i] != address(0));
      isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;
    fundRegistry = IFundRegistry(_fundRegistry);
  }

  modifier forbidden() {
    assert(false);
    _;
  }

  modifier onlyRole(bytes32 _role) {
    // Two
    //require(fundRegistry.getACL().hasRole(msg.sender, _role), "Invalid role");

    _;
  }

  function addOwner(address owner) public forbidden {}
  function removeOwner(address owner) public forbidden {}
  function replaceOwner(address owner, address newOwner) public forbidden {}
  function changeRequirement(uint _required) public forbidden {}

  function setOwners(address[] calldata _newOwners, uint256 _required) external onlyRole(ROLE_OWNER_MANAGER) {
    require(_required <= _newOwners.length, "Required too big");
    require(_required > 0, "Required too low");
    require(_fundStorage().areMembersValid(_newOwners), "Not all members are valid");

    owners = _newOwners;
    required = _required;

    emit NewOwnerSet(required, _newOwners.length);
  }

  // call has been separated into its own function in order to take advantage
  // of the Solidity's code generator to produce a loop that copies tx.data into memory.
  // solium-disable-next-line mixedcase
  function external_call(address destination, uint value, uint dataLength, bytes memory data) private returns (bool) {
    beforeTransactionHook(destination, value, dataLength, data);

    bool result;
    assembly {
        let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
        let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
        result := call(
            sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
                               // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                               // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            value,
            d,
            dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
        )
    }
    return result;
  }

  function beforeTransactionHook(address _destination, uint _value, uint _dataLength, bytes memory _data) private {
    if (_value > 0) {
      _fundStorage().handleMultiSigTransaction(ETH_CONTRACT_ADDRESS, _value);
    }

    (bool active,) = _fundStorage().periodLimits(_destination);

    // If a withdrawal limit exists for this t_destination
    if (active) {
      uint256 erc20Value;

      assembly {
        let code := mload(add(_data, 0x20))
        code := and(code, 0xffffffff00000000000000000000000000000000000000000000000000000000)

        switch code
        // transfer(address,uint256)
        case 0xa9059cbb00000000000000000000000000000000000000000000000000000000 {
          erc20Value := mload(add(_data, 0x44))
        }
        default {
          // Methods other than transfer are prohibited for ERC20 contracts
          revert(0, 0)
        }
      }

      if (erc20Value == 0) {
        return;
      }

      _fundStorage().handleMultiSigTransaction(_destination, erc20Value);
    }
  }

  function _fundStorage() internal view returns (IAbstractFundStorage) {
    return IAbstractFundStorage(fundRegistry.getStorageAddress());
  }
}

interface IFundRA {
  function balanceOf(address _owner) external view returns (uint256);
  function balanceOfAt(address _owner, uint256 _blockNumber) external view returns (uint256);
  function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
}

interface IAbstractFundStorage {
  function setConfigValue(bytes32 _key, bytes32 _value) external;

  function setDefaultProposalConfig(
    uint256 _support,
    uint256 _quorum,
    uint256 _timeout
  )
    external;

  function setProposalConfig(
    bytes32 _marker,
    uint256 _support,
    uint256 _quorum,
    uint256 _timeout
  )
    external;

  function addCommunityApp(
    address _contract,
    bytes32 _type,
    bytes32 _abiIpfsHash,
    string calldata _dataLink
  )
    external;
  function removeCommunityApp(address _contract) external;

  function addProposalMarker(
    bytes4 _methodSignature,
    address _destination,
    address _proposalManager,
    bytes32 _name,
    string calldata _dataLink
  )
    external;
  function removeProposalMarker(bytes32 _marker) external;
  function replaceProposalMarker(bytes32 _oldMarker, bytes32 _newMethodSignature, address _newDestination) external;

  function addFundRule(bytes32 _ipfsHash, string calldata _dataLink) external;

  function addFeeContract(address _feeContract) external;

  function removeFeeContract(address _feeContract) external;

  function setMemberIdentification(address _member, bytes32 _identificationHash) external;

  function disableFundRule(uint256 _id) external;

  function setNameAndDataLink(
    string calldata _name,
    string calldata _dataLink
  )
    external;

  function setMultiSigManager(
    bool _active,
    address _manager,
    string calldata _name,
    string calldata _dataLink
  )
    external;

  function setPeriodLimit(bool _active, address _erc20Contract, uint256 _amount) external;

  function handleMultiSigTransaction(
    address _erc20Contract,
    uint256 _amount
  )
    external;

  // GETTERS
  function membersIdentification(address _member) external view returns(bytes32);

  function getProposalVotingConfig(bytes32 _key) external view returns (uint256 support, uint256 quorum, uint256 timeout);

  function getThresholdMarker(address _destination, bytes calldata _data) external pure returns (bytes32 marker);

  function config(bytes32 _key) external view returns (bytes32);

  function getCommunityApps() external view returns (address[] memory);

  function getActiveFundRules() external view returns (uint256[] memory);

  function getActiveFundRulesCount() external view returns (uint256);

  function communityAppsInfo(
    address _contract
  )
    external
    view
    returns (
      bytes32 appType,
      bytes32 abiIpfsHash,
      string memory dataLink
    );

  function proposalMarkers(
    bytes32 _marker
  )
    external
    view
    returns (
      address proposalManager,
      address destination,
      bytes32 name,
      string memory dataLink
    );

  function areMembersValid(address[] calldata _members) external view returns (bool);

  function getActiveMultisigManagers() external view returns (address[] memory);

  function getActiveMultisigManagersCount() external view returns (uint256);

  function getActivePeriodLimits() external view returns (address[] memory);

  function getActivePeriodLimitsCount() external view returns (uint256);

  function getFeeContracts() external view returns (address[] memory);

  function getFeeContractCount() external view returns (uint256);

  function multiSigManagers(address _manager)
    external
    view
    returns (
      bool active,
      string memory managerName,
      string memory dataLink
    );

  function periodLimits(address _erc20Contract) external view returns (bool active, uint256 amount);
  function getCurrentPeriod() external view returns (uint256);
}

library ArraySet {
  struct AddressSet {
    address[] array;
    mapping(address => uint256) map;
    mapping(address => bool) exists;
  }

  struct Bytes32Set {
    bytes32[] array;
    mapping(bytes32 => uint256) map;
    mapping(bytes32 => bool) exists;
  }

  // AddressSet
  function add(AddressSet storage _set, address _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function addSilent(AddressSet storage _set, address _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);

    return true;
  }

  function remove(AddressSet storage _set, address _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(AddressSet storage _set, address _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(AddressSet storage _set, address _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    address lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(AddressSet storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      address v = _set.array[i];
      delete _set.map[v];
      _set.exists[v] = false;
    }

    delete _set.array;
  }

  function has(AddressSet storage _set, address _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(AddressSet storage _set) internal view returns (address[] storage) {
    return _set.array;
  }

  function size(AddressSet storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(AddressSet storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }

  // Bytes32Set
  function add(Bytes32Set storage _set, bytes32 _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _add(_set, _v);
  }

  function addSilent(Bytes32Set storage _set, bytes32 _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _add(_set, _v);

    return true;
  }

  function _add(Bytes32Set storage _set, bytes32 _v) internal {
    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function remove(Bytes32Set storage _set, bytes32 _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(Bytes32Set storage _set, bytes32 _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(Bytes32Set storage _set, bytes32 _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    bytes32 lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(Bytes32Set storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      _set.exists[_set.array[i]] = false;
    }

    delete _set.array;
  }

  function has(Bytes32Set storage _set, bytes32 _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(Bytes32Set storage _set) internal view returns (bytes32[] storage) {
    return _set.array;
  }

  function size(Bytes32Set storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(Bytes32Set storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }

  ///////////////////////////// Uint256Set /////////////////////////////////////////
  struct Uint256Set {
    uint256[] array;
    mapping(uint256 => uint256) map;
    mapping(uint256 => bool) exists;
  }

  function add(Uint256Set storage _set, uint256 _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _add(_set, _v);
  }

  function addSilent(Uint256Set storage _set, uint256 _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _add(_set, _v);

    return true;
  }

  function _add(Uint256Set storage _set, uint256 _v) internal {
    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function remove(Uint256Set storage _set, uint256 _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(Uint256Set storage _set, uint256 _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(Uint256Set storage _set, uint256 _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    uint256 lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(Uint256Set storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      _set.exists[_set.array[i]] = false;
    }

    delete _set.array;
  }

  function has(Uint256Set storage _set, uint256 _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(Uint256Set storage _set) internal view returns (uint256[] storage) {
    return _set.array;
  }

  function size(Uint256Set storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(Uint256Set storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract FundProposalManager is Initializable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  using ArraySet for ArraySet.AddressSet;
  using ArraySet for ArraySet.Uint256Set;

  // 100% == 100 ether
  uint256 public constant ONE_HUNDRED_PCT = 100 ether;

  event NewProposal(uint256 indexed proposalId, address indexed proposer, bytes32 indexed marker);
  event AyeProposal(uint256 indexed proposalId, address indexed voter);
  event NayProposal(uint256 indexed proposalId, address indexed voter);

  event Approved(uint256 ayeShare, uint256 support, uint256 indexed proposalId, bytes32 indexed marker);
  event Execute(uint256 indexed proposalId, address indexed executer, bool indexed success, bytes response);

  struct ProposalVoting {
    uint256 creationBlock;
    uint256 creationTotalSupply;
    uint256 createdAt;
    uint256 timeoutAt;
    uint256 requiredSupport;
    uint256 minAcceptQuorum;
    uint256 totalAyes;
    uint256 totalNays;
    mapping(address => Choice) participants;
    ArraySet.AddressSet ayes;
    ArraySet.AddressSet nays;
  }

  struct Proposal {
    ProposalStatus status;
    address creator;
    address destination;
    uint256 value;
    bytes32 marker;
    bytes data;
    string dataLink;
  }

  IFundRegistry public fundRegistry;
  Counters.Counter public idCounter;

  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => ProposalVoting) internal _proposalVotings;
  mapping(uint256 => address) private _proposalToSender;

  enum ProposalStatus {
    NULL,
    ACTIVE,
    EXECUTED
  }

  enum Choice {
    PENDING,
    AYE,
    NAY
  }

  modifier onlyMember() {
    require(_fundRA().balanceOf(msg.sender) > 0, "Not valid member");

    _;
  }

  constructor() public {
  }

  function initialize(IFundRegistry _fundRegistry) external isInitializer {
    fundRegistry = _fundRegistry;
  }

  function propose(
    address _destination,
    uint256 _value,
    bool _castVote,
    bool _executesIfDecided,
    bytes calldata _data,
    string calldata _dataLink
  )
    external
    onlyMember
  {
    idCounter.increment();
    uint256 id = idCounter.current();

    Proposal storage p = proposals[id];
    p.creator = msg.sender;
    p.destination = _destination;
    p.value = _value;
    p.data = _data;
    p.dataLink = _dataLink;
    p.marker = _fundStorage().getThresholdMarker(_destination, _data);

    p.status = ProposalStatus.ACTIVE;
    _onNewProposal(id);

    emit NewProposal(id, msg.sender, p.marker);

    if (_castVote) {
      _aye(id, msg.sender, _executesIfDecided);
    }
  }

  function aye(uint256 _proposalId, bool _executeIfDecided) external {
    require(_isProposalOpen(_proposalId), "Proposal isn't open");

    _aye(_proposalId, msg.sender, _executeIfDecided);
  }

  function nay(uint256 _proposalId) external {
    require(_isProposalOpen(_proposalId), "Proposal isn't open");

    _nay(_proposalId, msg.sender);
  }

  function executeProposal(uint256 _proposalId, uint256 _gasToKeep) external {
    require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal isn't active");

    (bool canExecuteThis, string memory reason) = _canExecute(_proposalId);
    require(canExecuteThis, reason);

    _unsafeExecuteProposal(_proposalId, _gasToKeep);
  }

  // INTERNAL

  function _aye(uint256 _proposalId, address _voter, bool _executeIfDecided) internal {
    ProposalVoting storage pV = _proposalVotings[_proposalId];
    uint256 reputation = reputationOf(_voter, pV.creationBlock);
    require(reputation > 0, "Can't vote with 0 reputation");

    if (pV.participants[_voter] == Choice.NAY) {
      pV.nays.remove(_voter);
      pV.totalNays = pV.totalNays.sub(reputation);
    }

    pV.participants[_voter] = Choice.AYE;
    pV.ayes.add(_voter);
    pV.totalAyes = pV.totalAyes.add(reputation);

    emit AyeProposal(_proposalId, _voter);

    (bool canExecuteThis,) = _canExecute(_proposalId);

    // Fail silently without revert
    if (_executeIfDecided && canExecuteThis) {
      // We've already checked if the vote can be executed with `_canExecute()`
      _unsafeExecuteProposal(_proposalId, 0);
    }
  }

  function _nay(uint256 _proposalId, address _voter) internal {
    ProposalVoting storage pV = _proposalVotings[_proposalId];
    uint256 reputation = reputationOf(_voter, pV.creationBlock);
    require(reputation > 0, "Can't vote with 0 reputation");

    if (pV.participants[_voter] == Choice.AYE) {
      pV.ayes.remove(_voter);
      pV.totalAyes = pV.totalAyes.sub(reputation);
    }

    pV.participants[msg.sender] = Choice.NAY;
    pV.nays.add(msg.sender);
    pV.totalNays = pV.totalNays.add(reputation);

    emit NayProposal(_proposalId, _voter);
  }

  function _onNewProposal(uint256 _proposalId) internal {
    bytes32 marker = proposals[_proposalId].marker;

    uint256 blockNumber = block.number.sub(1);
    uint256 totalSupply = _fundRA().totalSupplyAt(blockNumber);
    require(totalSupply > 0, "Total reputation is 0");

    ProposalVoting storage pv = _proposalVotings[_proposalId];

    pv.creationBlock = blockNumber;
    pv.creationTotalSupply = totalSupply;

    (uint256 support, uint256 quorum, uint256 timeout) = _fundStorage().getProposalVotingConfig(marker);
    pv.createdAt = block.timestamp;
    // pv.timeoutAt = block.timestamp + timeout;
    pv.timeoutAt = block.timestamp.add(timeout);

    pv.requiredSupport = support;
    pv.minAcceptQuorum = quorum;
  }

  function _unsafeExecuteProposal(uint256 _proposalId, uint256 _gasToKeep) internal {
    uint256 gasToKeep = 0;
    if (_gasToKeep == 0) {
      gasToKeep = 100000;
    }

    Proposal storage p = proposals[_proposalId];

    p.status = ProposalStatus.EXECUTED;

    (bool ok, bytes memory response) = address(p.destination)
      .call
      .value(p.value)
      .gas(gasleft().sub(gasToKeep))(p.data);

    if (ok == false) {
      p.status = ProposalStatus.ACTIVE;
    }

    emit Execute(_proposalId, msg.sender, ok, response);
  }

  function _canExecute(uint256 _proposalId) internal view returns (bool can, string memory errorReason) {
    Proposal storage p = proposals[_proposalId];
    ProposalVoting storage pv = _proposalVotings[_proposalId];

    // Voting is not executed yet
    if (p.status != ProposalStatus.ACTIVE) {
      return (false, "Proposal isn't active");
    }

    // Voting is already decided
    if (_isValuePct(pv.totalAyes, pv.creationTotalSupply, pv.requiredSupport)) {
      return (true, "");
    }

    // Vote ended?
    if (_isProposalOpen(_proposalId)) {
      return (false, "Proposal is still active");
    }

    // Has enough support?
    uint256 support = getCurrentSupport(_proposalId);
    if (support < pv.requiredSupport) {
      return (false, "Support hasn't been reached");
    }

    // Has min quorum?
    uint256 ayeShare = getAyeShare(_proposalId);
    if (ayeShare < pv.minAcceptQuorum) {
      return (false, "MIN aye quorum hasn't been reached");
    }

    return (true, "");
  }

  function _isValuePct(uint256 _value, uint256 _total, uint256 _pct) internal pure returns (bool) {
    if (_total == 0) {
      return false;
    }

    uint256 computedPct = _value.mul(ONE_HUNDRED_PCT) / _total;
    return computedPct > _pct;
  }

  function _isProposalOpen(uint256 _proposalId) internal view returns (bool) {
    Proposal storage p = proposals[_proposalId];
    ProposalVoting storage pv = _proposalVotings[_proposalId];

    return block.timestamp < pv.timeoutAt && p.status == ProposalStatus.ACTIVE;
  }

  function _fundStorage() internal view returns (IAbstractFundStorage) {
    return IAbstractFundStorage(fundRegistry.getStorageAddress());
  }

  function _fundRA() internal view returns (IFundRA) {
    return IFundRA(fundRegistry.getRAAddress());
  }

  // GETTERS

  function getProposalVoting(
    uint256 _proposalId
  )
    external
    view
    returns (
      uint256 creationBlock,
      uint256 creationTotalSupply,
      uint256 totalAyes,
      uint256 totalNays,
      address[] memory ayes,
      address[] memory nays
    )
  {
    ProposalVoting storage pV = _proposalVotings[_proposalId];

    return (
      pV.creationBlock,
      pV.creationTotalSupply,
      pV.totalAyes,
      pV.totalNays,
      pV.ayes.elements(),
      pV.nays.elements()
    );
  }

  function getProposalVotingProgress(
    uint256 _proposalId
  )
    external
    view
    returns (
      uint256 ayesShare,
      uint256 naysShare,
      uint256 totalAyes,
      uint256 totalNays,
      uint256 currentSupport,
      uint256 requiredSupport,
      uint256 minAcceptQuorum,
      uint256 timeoutAt
    )
  {
    ProposalVoting storage pV = _proposalVotings[_proposalId];

    return (
      getAyeShare(_proposalId),
      getNayShare(_proposalId),
      pV.totalAyes,
      pV.totalNays,
      getCurrentSupport(_proposalId),
      pV.requiredSupport,
      pV.minAcceptQuorum,
      pV.timeoutAt
    );
  }

  function reputationOf(address _address, uint256 _blockNumber) public view returns (uint256) {
    return _fundRA().balanceOfAt(_address, _blockNumber);
  }

  function canExecute(uint256 _proposalId) external view returns (bool can, string memory errorReason) {
    return _canExecute(_proposalId);
  }

  function getParticipantProposalChoice(uint256 _proposalId, address _participant) external view returns (Choice) {
    return _proposalVotings[_proposalId].participants[_participant];
  }

  function getCurrentSupport(uint256 _proposalId) public view returns (uint256) {
    ProposalVoting storage pv = _proposalVotings[_proposalId];

    uint256 totalVotes = pv.totalAyes.add(pv.totalNays);

    if (totalVotes == 0) {
      return 0;
    }

    return pv.totalAyes.mul(ONE_HUNDRED_PCT) / totalVotes;
  }

  function getAyeShare(uint256 _proposalId) public view returns (uint256) {
    ProposalVoting storage p = _proposalVotings[_proposalId];

    return p.totalAyes.mul(ONE_HUNDRED_PCT) / p.creationTotalSupply;
  }

  function getNayShare(uint256 _proposalId) public view returns (uint256) {
    ProposalVoting storage p = _proposalVotings[_proposalId];

    return p.totalNays.mul(ONE_HUNDRED_PCT) / p.creationTotalSupply;
  }
}

contract AbstractFundStorage is IAbstractFundStorage, Initializable {
  using SafeMath for uint256;
  IFundRegistry public fundRegistry;
  bytes32 public constant ROLE_EXPEL_MEMBER_MANAGER = bytes32("EXPEL_MEMBER_MANAGER");
  modifier onlyRole(bytes32 _role) {
    // One
    require(fundRegistry.getACL().hasRole(msg.sender, _role), "Invalid role");

    _;
  }
  // GETTERS

  function getThresholdMarker(address _destination, bytes memory _data) public pure returns(bytes32 marker) {
    bytes32 methodName;

    assembly {
      methodName := and(mload(add(_data, 0x20)), 0xffffffff00000000000000000000000000000000000000000000000000000000)
    }

    return keccak256(abi.encode(_destination, methodName));
  }

  function getProposalVotingConfig(
    bytes32 _key
  )
    external
    view
    returns (uint256 support, uint256 minAcceptQuorum, uint256 timeout)
  {
    uint256 to = customVotingConfigs[_key].timeout;

    if (to > 0) {
      return (
        customVotingConfigs[_key].support,
        customVotingConfigs[_key].minAcceptQuorum,
        customVotingConfigs[_key].timeout
      );
    } else {
      return (
        defaultVotingConfig.support,
        defaultVotingConfig.minAcceptQuorum,
        defaultVotingConfig.timeout
      );
    }
  }

  function getCommunityApps() external view returns (address[] memory) {
    return _communityApps.elements();
  }

  function getActiveFundRules() external view returns (uint256[] memory) {
    return _activeFundRules.elements();
  }

  function getActiveFundRulesCount() external view returns (uint256) {
    return _activeFundRules.size();
  }

  function areMembersValid(address[] calldata _members) external view returns (bool) {
    uint256 len = _members.length;

    for (uint256 i = 0; i < len; i++) {
      if (multiSigManagers[_members[i]].active == false) {
        return false;
      }
    }

    return true;
  }

  function getActiveMultisigManagers() external view returns (address[] memory) {
    return _activeMultisigManagers.elements();
  }

  function getActiveMultisigManagersCount() external view returns (uint256) {
    return _activeMultisigManagers.size();
  }

  function getActivePeriodLimits() external view returns (address[] memory) {
    return _activePeriodLimitsContracts.elements();
  }

  function getActivePeriodLimitsCount() external view returns (uint256) {
    return _activePeriodLimitsContracts.size();
  }

  function getFeeContracts() external view returns (address[] memory) {
    return _feeContracts.elements();
  }

  function getFeeContractCount() external view returns (uint256) {
    return _feeContracts.size();
  }

  function getCurrentPeriod() public view returns (uint256) {
    // return (block.timestamp - initialTimestamp) / periodLength;
    return (block.timestamp.sub(initialTimestamp)) / periodLength;
  }

  using ArraySet for ArraySet.AddressSet;
  using ArraySet for ArraySet.Uint256Set;
  using ArraySet for ArraySet.Bytes32Set;
  using Counters for Counters.Counter;

  event AddProposalMarker(bytes32 indexed marker, address indexed proposalManager);
  event RemoveProposalMarker(bytes32 indexed marker, address indexed proposalManager);
  event ReplaceProposalMarker(bytes32 indexed oldMarker, bytes32 indexed newMarker, address indexed proposalManager);

  event SetProposalVotingConfig(bytes32 indexed key, uint256 support, uint256 minAcceptQuorum, uint256 timeout);
  event SetDefaultProposalVotingConfig(uint256 support, uint256 minAcceptQuorum, uint256 timeout);

  event AddCommunityApp(address indexed contractAddress);
  event RemoveCommunityApp(address indexed contractAddress);

  event AddFundRule(uint256 indexed id);
  event DisableFundRule(uint256 indexed id);

  event AddFeeContract(address indexed contractAddress);
  event RemoveFeeContract(address indexed contractAddress);

  event SetMemberIdentification(address indexed member, bytes32 identificationHash);
  event SetNameAndDataLink(string name, string dataLink);
  event SetMultiSigManager(address indexed manager);
  event SetPeriodLimit(address indexed erc20Contract, uint256 amount, bool active);
  event HandleMultiSigTransaction(address indexed erc20Contract, uint256 amount);

  event SetConfig(bytes32 indexed key, bytes32 value);

  // 100% == 100 ether
  uint256 public constant ONE_HUNDRED_PCT = 100 ether;

  bytes32 public constant ROLE_CONFIG_MANAGER = bytes32("CONFIG_MANAGER");
  bytes32 public constant ROLE_COMMUNITY_APPS_MANAGER = bytes32("CA_MANAGER");
  bytes32 public constant ROLE_PROPOSAL_MARKERS_MANAGER = bytes32("MARKER_MANAGER");
  bytes32 public constant ROLE_NEW_MEMBER_MANAGER = bytes32("NEW_MEMBER_MANAGER");
  bytes32 public constant ROLE_FINE_MEMBER_INCREMENT_MANAGER = bytes32("FINE_MEMBER_INCREMENT_MANAGER");
  bytes32 public constant ROLE_FINE_MEMBER_DECREMENT_MANAGER = bytes32("FINE_MEMBER_DECREMENT_MANAGER");
  bytes32 public constant ROLE_CHANGE_NAME_AND_DESCRIPTION_MANAGER = bytes32("CHANGE_NAME_DATA_LINK_MANAGER");
  bytes32 public constant ROLE_ADD_FUND_RULE_MANAGER = bytes32("ADD_FUND_RULE_MANAGER");
  bytes32 public constant ROLE_DEACTIVATE_FUND_RULE_MANAGER = bytes32("DEACTIVATE_FUND_RULE_MANAGER");
  bytes32 public constant ROLE_FEE_MANAGER = bytes32("FEE_MANAGER");
  bytes32 public constant ROLE_MEMBER_DETAILS_MANAGER = bytes32("MEMBER_DETAILS_MANAGER");
  bytes32 public constant ROLE_MULTI_SIG_WITHDRAWAL_LIMITS_MANAGER = bytes32("MULTISIG_WITHDRAWAL_MANAGER");
  bytes32 public constant ROLE_MEMBER_IDENTIFICATION_MANAGER = bytes32("MEMBER_IDENTIFICATION_MANAGER");
  bytes32 public constant ROLE_PROPOSAL_THRESHOLD_MANAGER = bytes32("THRESHOLD_MANAGER");
  bytes32 public constant ROLE_DEFAULT_PROPOSAL_THRESHOLD_MANAGER = bytes32("DEFAULT_THRESHOLD_MANAGER");
  bytes32 public constant ROLE_DECREMENT_TOKEN_REPUTATION = bytes32("DECREMENT_TOKEN_REPUTATION_ROLE");
  bytes32 public constant ROLE_MULTISIG = bytes32("MULTISIG");

  bytes32 public constant IS_PRIVATE = bytes32("is_private");

  struct FundRule {
    bool active;
    uint256 id;
    address manager;
    bytes32 ipfsHash;
    string dataLink;
    uint256 createdAt;
  }

  struct CommunityApp {
    bytes32 abiIpfsHash;
    bytes32 appType;
    string dataLink;
  }

  struct ProposalMarker {
    bool active;
    bytes32 name;
    string dataLink;
    address destination;
    address proposalManager;
  }

  struct MultiSigManager {
    bool active;
    address manager;
    string name;
    string dataLink;
  }

  struct MemberFines {
    uint256 total;
    // Assume ETH is address(0x1)
    mapping(address => MemberFineItem) tokenFines;
  }

  struct MemberFineItem {
    uint256 amount;
  }

  struct PeriodLimit {
    bool active;
    uint256 amount;
  }

  struct VotingConfig {
    uint256 support;
    uint256 minAcceptQuorum;
    uint256 timeout;
  }

  VotingConfig public defaultVotingConfig;

  string public name;
  string public dataLink;
  uint256 public initialTimestamp;
  uint256 public periodLength;

  ArraySet.AddressSet internal _communityApps;
  ArraySet.Uint256Set internal _activeFundRules;
  ArraySet.AddressSet internal _feeContracts;

  Counters.Counter internal fundRuleCounter;

  ArraySet.AddressSet internal _activeMultisigManagers;
  ArraySet.AddressSet internal _activePeriodLimitsContracts;

  mapping(bytes32 => bytes32) public config;
  // contractAddress => details
  mapping(address => CommunityApp) public communityAppsInfo;
  // marker => details
  mapping(bytes32 => ProposalMarker) public proposalMarkers;
  // role => address
  mapping(bytes32 => address) public coreContracts;
  // manager => details
  mapping(address => MultiSigManager) public multiSigManagers;
  // erc20Contract => details
  mapping(address => PeriodLimit) public periodLimits;
  // periodId => (erc20Contract => runningTotal)
  mapping(uint256 => mapping(address => uint256)) internal _periodRunningTotals;
  // member => identification hash
  mapping(address => bytes32) public membersIdentification;

  // FRP => fundRuleDetails
  mapping(uint256 => FundRule) public fundRules;

  // marker => customVotingConfigs
  mapping(bytes32 => VotingConfig) public customVotingConfigs;

  modifier onlyFeeContract() {
    require(_feeContracts.has(msg.sender), "Not a fee contract");

    _;
  }

  modifier onlyMultiSig() {
    require(fundRegistry.getACL().hasRole(msg.sender, ROLE_MULTISIG), "Invalid role");

    _;
  }


  constructor() public {
  }

  function initialize(
    IFundRegistry _fundRegistry,
    bool _isPrivate,
    uint256 _defaultProposalSupport,
    uint256 _defaultProposalMinAcceptQuorum,
    uint256 _defaultProposalTimeout,
    uint256 _periodLength
  )
    external
    isInitializer
  {
    config[IS_PRIVATE] = _isPrivate ? bytes32(uint256(1)) : bytes32(uint256(0));

    periodLength = _periodLength;
    initialTimestamp = block.timestamp;

    _validateVotingConfig(_defaultProposalSupport, _defaultProposalMinAcceptQuorum, _defaultProposalTimeout);

    defaultVotingConfig.support = _defaultProposalSupport;
    defaultVotingConfig.minAcceptQuorum = _defaultProposalMinAcceptQuorum;
    defaultVotingConfig.timeout = _defaultProposalTimeout;

    fundRegistry = _fundRegistry;
  }

  function setDefaultProposalConfig(
    uint256 _support,
    uint256 _minAcceptQuorum,
    uint256 _timeout
  )
    external
    onlyRole(ROLE_DEFAULT_PROPOSAL_THRESHOLD_MANAGER)
  {
    _validateVotingConfig(_support, _minAcceptQuorum, _timeout);

    defaultVotingConfig.support = _support;
    defaultVotingConfig.minAcceptQuorum = _minAcceptQuorum;
    defaultVotingConfig.timeout = _timeout;

    emit SetDefaultProposalVotingConfig(_support, _minAcceptQuorum, _timeout);
  }

  function setProposalConfig(
    bytes32 _marker,
    uint256 _support,
    uint256 _minAcceptQuorum,
    uint256 _timeout
  )
    external
    onlyRole(ROLE_PROPOSAL_THRESHOLD_MANAGER)
  {
    _validateVotingConfig(_support, _minAcceptQuorum, _timeout);

    customVotingConfigs[_marker] = VotingConfig({
      support: _support,
      minAcceptQuorum: _minAcceptQuorum,
      timeout: _timeout
    });

    emit SetProposalVotingConfig(_marker, _support, _minAcceptQuorum, _timeout);
  }

  function setConfigValue(bytes32 _key, bytes32 _value) external onlyRole(ROLE_CONFIG_MANAGER) {
    config[_key] = _value;

    emit SetConfig(_key, _value);
  }

  function addCommunityApp(
    address _contract,
    bytes32 _type,
    bytes32 _abiIpfsHash,
    string calldata _dataLink
  )
    external
    onlyRole(ROLE_COMMUNITY_APPS_MANAGER)
  {
    CommunityApp storage c = communityAppsInfo[_contract];

    _communityApps.addSilent(_contract);

    c.appType = _type;
    c.abiIpfsHash = _abiIpfsHash;
    c.dataLink = _dataLink;

    emit AddCommunityApp(_contract);
  }

  function removeCommunityApp(address _contract) external onlyRole(ROLE_COMMUNITY_APPS_MANAGER) {
    _communityApps.remove(_contract);

    emit RemoveCommunityApp(_contract);
  }

  function addProposalMarker(
    bytes4 _methodSignature,
    address _destination,
    address _proposalManager,
    bytes32 _name,
    string calldata _dataLink
  )
    external
    onlyRole(ROLE_PROPOSAL_MARKERS_MANAGER)
  {
    bytes32 _marker = keccak256(abi.encode(_destination, _methodSignature));

    ProposalMarker storage m = proposalMarkers[_marker];

    m.active = true;
    m.proposalManager = _proposalManager;
    m.destination = _destination;
    m.name = _name;
    m.dataLink = _dataLink;

    emit AddProposalMarker(_marker, _proposalManager);
  }

  function removeProposalMarker(bytes32 _marker) external onlyRole(ROLE_PROPOSAL_MARKERS_MANAGER) {
    proposalMarkers[_marker].active = false;

    emit RemoveProposalMarker(_marker, proposalMarkers[_marker].proposalManager);
  }

  function replaceProposalMarker(
    bytes32 _oldMarker,
    bytes32 _newMethodSignature,
    address _newDestination
  )
    external
    onlyRole(ROLE_PROPOSAL_MARKERS_MANAGER)
  {
    bytes32 _newMarker = keccak256(abi.encode(_newDestination, _newMethodSignature));

    proposalMarkers[_newMarker] = proposalMarkers[_oldMarker];
    proposalMarkers[_newMarker].destination = _newDestination;
    proposalMarkers[_oldMarker].active = false;

    emit ReplaceProposalMarker(_oldMarker, _newMarker, proposalMarkers[_newMarker].proposalManager);
  }

  function addFundRule(
    bytes32 _ipfsHash,
    string calldata _dataLink
  )
    external
    onlyRole(ROLE_ADD_FUND_RULE_MANAGER)
  {
    fundRuleCounter.increment();
    uint256 _id = fundRuleCounter.current();

    FundRule storage fundRule = fundRules[_id];

    fundRule.active = true;
    fundRule.id = _id;
    fundRule.ipfsHash = _ipfsHash;
    fundRule.dataLink = _dataLink;
    fundRule.manager = msg.sender;
    fundRule.createdAt = block.timestamp;

    _activeFundRules.add(_id);

    emit AddFundRule(_id);
  }

  function disableFundRule(uint256 _id) external onlyRole(ROLE_DEACTIVATE_FUND_RULE_MANAGER) {
    fundRules[_id].active = false;

    _activeFundRules.remove(_id);

    emit DisableFundRule(_id);
  }

  function addFeeContract(address _feeContract) external onlyRole(ROLE_FEE_MANAGER) {
    _feeContracts.add(_feeContract);

    emit AddFeeContract(_feeContract);
  }

  function removeFeeContract(address _feeContract) external onlyRole(ROLE_FEE_MANAGER) {
    _feeContracts.remove(_feeContract);

    emit RemoveFeeContract(_feeContract);
  }

  function setMemberIdentification(address _member, bytes32 _identificationHash) external onlyRole(ROLE_MEMBER_IDENTIFICATION_MANAGER) {
    membersIdentification[_member] = _identificationHash;

    emit SetMemberIdentification(_member, _identificationHash);
  }

  function setNameAndDataLink(
    string calldata _name,
    string calldata _dataLink
  )
    external
    onlyRole(ROLE_CHANGE_NAME_AND_DESCRIPTION_MANAGER)
  {
    name = _name;
    dataLink = _dataLink;

    emit SetNameAndDataLink(_name, _dataLink);
  }

  function setMultiSigManager(
    bool _active,
    address _manager,
    string calldata _name,
    string calldata _dataLink
  )
    external
    onlyRole(ROLE_MEMBER_DETAILS_MANAGER)
  {
    MultiSigManager storage m = multiSigManagers[_manager];

    m.active = _active;
    m.name = _name;
    m.dataLink = _dataLink;

    if (_active) {
      _activeMultisigManagers.addSilent(_manager);
    } else {
      _activeMultisigManagers.removeSilent(_manager);
    }

    emit SetMultiSigManager(_manager);
  }

  function setPeriodLimit(
    bool _active,
    address _erc20Contract,
    uint256 _amount
  )
    external
    onlyRole(ROLE_MULTI_SIG_WITHDRAWAL_LIMITS_MANAGER)
  {
    periodLimits[_erc20Contract].active = _active;
    periodLimits[_erc20Contract].amount = _amount;

    if (_active) {
      _activePeriodLimitsContracts.addSilent(_erc20Contract);
    } else {
      _activePeriodLimitsContracts.removeSilent(_erc20Contract);
    }

    emit SetPeriodLimit(_erc20Contract, _amount, _active);
  }

  function handleMultiSigTransaction(
    address _erc20Contract,
    uint256 _amount
  )
    external
    onlyMultiSig
  {
    PeriodLimit storage limit = periodLimits[_erc20Contract];
    if (limit.active == false) {
      return;
    }

    uint256 currentPeriod = getCurrentPeriod();
    // uint256 runningTotalAfter = _periodRunningTotals[currentPeriod][_erc20Contract] + _amount;
    uint256 runningTotalAfter = _periodRunningTotals[currentPeriod][_erc20Contract].add(_amount);

    require(runningTotalAfter <= periodLimits[_erc20Contract].amount, "Running total for the current period exceeds the limit");
    _periodRunningTotals[currentPeriod][_erc20Contract] = runningTotalAfter;

    emit HandleMultiSigTransaction(_erc20Contract, _amount);
  }

  //// INTERNAL

  function _validateVotingConfig(
    uint256 _support,
    uint256 _minAcceptQuorum,
    uint256 _timeout
  )
    internal
    pure
  {
    require(_minAcceptQuorum > 0 && _minAcceptQuorum <= _support, "Invalid min accept quorum value");
    require(_support > 0 && _support <= ONE_HUNDRED_PCT, "Invalid support value");
    require(_timeout > 0, "Invalid duration value");
  }

}


contract IERC721{
    function ownerOf(uint256 tokenId) public view returns (address owner);

}

interface IPPToken {
}

interface IPPLocker {
  function reputation() external view returns(uint256);
}

contract PrivateFundStorage is AbstractFundStorage {

  function expel(address _registry, uint256 _tokenId)
    external
    onlyRole(ROLE_EXPEL_MEMBER_MANAGER)
  {
    address owner;
    owner = IERC721(_registry).ownerOf(_tokenId);
    uint256 amount = IPPLocker(owner).reputation();

  }

}

