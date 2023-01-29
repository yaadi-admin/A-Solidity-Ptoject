// SPDX-License_Identifier: MIT
pragma solidity ^0.8.17;

// Essentially, a smart contract can be thought of as a programmable
// intermediary which can facilitate transactions between parties
// and autonomously settling disputes. Which is perfect for something
// like a 'Last Will And Testament' to distribute an inheritance
// to various beneficiaries.

// EXERCISE:
// --------
// 1. Refactor the code to use an array of structs to hold the beneficiary information,
// without using a mapping.
// 2. Create a function to translate the Value entered in Ether to Wei.
// 3. Add require statements to make sure the balance in the contract is sufficient to
// cover the setInheritance values.

contract LastWillAndTestament {
    address owner;

    uint256 funds;

    bool isDeceased;

    uint256 public deceasedTimestamp;

    uint256 currentTime = block.timestamp;

    // Necessary to hold the transfer while the one week time frame comes to a close.
    enum State {
        AWAITING_DEATH,
        AWAITING,
        DEAD
    }

    State public currentState;

    struct Beneficiary {
        address payable account;
        uint256 amount;
    }

    Beneficiary[] public beneficiaries;

    constructor() payable {
        owner = msg.sender;

        funds = msg.value;

        isDeceased = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of the contract.");

        _;
    }

    modifier onlyOwnerOrBeneficiary(address _beneficiary) {
        require(
            msg.sender == owner || checkSenderAddress(_beneficiary),
            "You are not the owner of the contract nor a beneficiary."
        );
        _;
    }

    modifier isOwnerDeceased() {
        require(
            isDeceased == true,
            "Contract owner must be deceased for funds to be distributed."
        );

        _;
    }

    modifier isBalanceEnough(uint256 _transferAmount) {
        require(
            address(this).balance >= _transferAmount,
            "Not enough funds is available to make this transfer"
        );
        _;
    }

    modifier isDeceasedTimeout() {
        require(
            block.timestamp <= deceasedTimestamp + 1 weeks,
            "Timeout for owner to verify proof of life has expired."
        );
        _;
    }

    // This emulates 'iterating over a mapping' which cannot be done directly.

    // Here we are iterating over an array of keys

    // to plug into the mapping to get the associated value.

    address payable[] beneficiaryAccounts;

    mapping(address => uint256) inheritance;

    function setInheritance(address payable _account, uint256 _inheritAmt)
        public
        onlyOwner
        isBalanceEnough(_inheritAmt)
    {
        // beneficiaryAccounts.push(_account);

        // inheritance[_account] = _inheritAmt;

        // The conntract accepted Ether as payment which did not require conversion to Wei
        // However the transfers are done in Wei so i have done the conversion to Ether
        beneficiaries.push(
            Beneficiary(_account, (_inheritAmt * 1000000000000000000))
        );
    }

    function checkBeneficiaryAddress(address payable _address)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i].account == _address) {
                return true;
            }
        }
        return false;
    }

    function checkSenderAddress(address _address) private view returns (bool) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i].account == _address) {
                return true;
            }
        }
        return false;
    }

    function distributeFunds() private isOwnerDeceased {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(
                address(this).balance >= beneficiaries[i].amount,
                "Not enough funds available in the contract to make this transfer"
            );
            require(
                checkBeneficiaryAddress(beneficiaries[i].account),
                "Hmm, something doesn't look right!"
            );
            beneficiaries[i].account.transfer(beneficiaries[i].amount);
        }
    }

    // QUESTION? How would this function get called if the owner is deceased?
    // ANSWER: Well the aim is to issue the funds to the beneficiaries when
    // the owner dies so the beneficiaries can be a means of aquiring that information
    // Allowinng the beneficiary to initiate the deceased function.
    // as a precaution this function will initiate for only a week before being defaulted by action two
    // action two just checks to see if the owner has set the is deceased variale back to false;

    function updateIsDeceased(bool _isDeceased)
        public
        onlyOwner
        isDeceasedTimeout
    {
        isDeceased = _isDeceased;
        currentState = State.AWAITING_DEATH;
    }

    // It sets the state of the contract to "deceased" by setting the "isDeceased" variable to "true".
    // It records the timestamp at which the contract was set to "deceased" by setting the "deceasedTimestamp" variable to the current block's timestamp.
    // It requires that the current state of the contract must be "AWAITING" and that the current block's timestamp must be greater than one week after the current time. If either of these conditions are not met, it will revert with the error message "Proof of life has started, this contract will execute in one week."
    // It calls the "distributeFunds" function, which presumably distributes the funds associated with the contract to the appropriate parties.
    // It sets the current state of the contract to "DEAD."

    function deceased() public onlyOwnerOrBeneficiary(msg.sender) {
        isDeceased = true;
        deceasedTimestamp = block.timestamp;
        currentState = State.AWAITING;
        require(
            currentState == State.AWAITING &&
                block.timestamp >= (currentTime + 1 weeks),
            "Proof of life has started, this contract will execute in one week"
        );
        distributeFunds();
        currentState = State.DEAD;
    }

    // NOTE The deceased transaction will continuously fail 
    // while the current date is less than a week from the block timestamp
    // However that is the intended output
    // The frontend will be able to utilize that feedback
}
