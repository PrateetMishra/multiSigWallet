// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MultiSigWallet {
    //events are fired when for example something will deposit in event Deposit()
    //and emit the events when required
    event Deposit(address indexed sender, uint256 amount);

    event Submit(uint256 indexed transactionID);
    //sumbit the transaction
    event Approve(address indexed owner, uint256 indexed transactionID);
    //Approval of transaction by different owners
    event Revoke(address indexed owner, uint256 indexed transactionID);
    //if the owners change their mind they can revoke
    event Execute(uint256 indexed transactionID);
    //Execution of contract when there are sufficient amount of approvals

    //to store transaction
    struct Transaction {
        address to;
        uint256 value;
        bytes data; //string type takes more gas than bytes
        bool executed;
    }

    address[] public owners;
    //array of type address which will store address of owners
    mapping(address => bool) public isOwner;
    //to check if msg.sender is owner or not
    uint256 public requiredApprovals;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    //for checking if its the owner or not
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner!");
        _;
    }

    //for checking if transaction exists or not
    modifier txExists(uint256 _txID) {
        require(_txID < transactions.length, "Transaction does not exist!");
        _;
    }

    //for checking if transaction is approved or not
    modifier notYetApproved(uint256 _txID) {
        require(!approved[_txID][msg.sender], "Transaction already approved!");
        _;
    }

    //for checking if transaction is executed or not
    modifier notYetExecuted(uint256 _txID) {
        require(!transactions[_txID].executed, "Transaction already executed!");
        _;
    }

    //Had some error while passing contructor arguments while deploying!

    //constructor(address[] memory _owners, uint256 _requiredApprovals) {
    //    require(_owners.length > 0, "Owners Required!");
    //    require(
    //        _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
    //        "Invalid required number of owners!"
    //    );
    //    for (uint256 i; i < _owners.length; i++) {
    //        address owner = _owners[i];
    //        require(owner != address(0), "Invalid Owner!");
    //        require(!isOwner[owner], "Owner is not unique!");
    //        isOwner[owner] = true;
    //        owners.push(owner);
    //    }

    //    requiredApprovals = _requiredApprovals;
    // }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _txID)
        external
        onlyOwner
        txExists(_txID)
        notYetApproved(_txID)
        notYetExecuted(_txID)
    {
        approved[_txID][msg.sender] = true;
        emit Approve(msg.sender, _txID);
    }

    function getApprovalCount(uint256 _txID)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txID][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txID)
        external
        txExists(_txID)
        notYetExecuted(_txID)
    {
        require(
            getApprovalCount(_txID) >= requiredApprovals,
            "Approvals is less than required!"
        );
        Transaction storage transaction = transactions[_txID];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "transaction Failed");
        emit Execute(_txID);
    }

    function revoke(uint256 _txID)
        external
        onlyOwner
        txExists(_txID)
        notYetExecuted(_txID)
    {
        require(approved[_txID][msg.sender], "Transaction not approved!");
        approved[_txID][msg.sender] = false;
        emit Revoke(msg.sender, _txID);
    }
}
