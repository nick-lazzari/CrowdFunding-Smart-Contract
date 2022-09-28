// SPDX-License-Identifier: MIT


// Blockchain can solve the issue of fradulent crowdfunding campaigns

// Admin will start crowdfunding campaign - define specific goal and deadline
// Contributers will contribute by sending ETH
// Admin must create spending request to spend money
// Contributors vote on spending request
// If more than 50% of votes are achieved for request, admin can spend the requested amount
// If monetary goal is not reached in deadline, contributors can request a refund
// ^^ Moves power from owner to contributor

pragma solidity ^0.8.0;

contract Crowdfunding {
    mapping(address => uint) public contributors; // Maps address to amount contributed
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline; // Timestamp
    uint public goal;
    uint public raisedAmount;
    struct Request {
        string description; 
        address payable recipient; 
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;

    uint public numRequests; // Necessary because mappings do not use increments or indexes

    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline; // Will add a deadline starting from current timestamp of block
        minimumContribution = 100 wei;
        admin = msg.sender;
    } 

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum contribution not met");

        if(contributors[msg.sender] == 0) { // If the user has not contributed to the fundraiser yet, contributors will updated
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value; // Updates amount a specific address has contributed
        raisedAmount += msg.value; // Updates total amount raised

        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable external {
        contribute(); // When address sends funds to the contract, contribute() function will execute
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender); // Address that calls function gets stored in recipient
        uint value = contributors[msg.sender]; // Value from mapping associated with address

        recipient.transfer(value); // Transfers value back to recipient

        contributors[msg.sender] = 0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        // Function creates an instance of Request struct called newRequest
        // This newRequest will be given a number identifier (numRequests)
        // Using this number, we are able to access the specific request in the mapping (requests)
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);

    }

    function voteRequest(uint _requestNumber) public {
        require(contributors[msg.sender] > 0, "Must be a contributor to vote");

        // Accesses request based on user input
        // Comes from mapping (reuquests)
        Request storage thisRequest = requests[_requestNumber];

        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNumber) public onlyAdmin {
        require(raisedAmount >= goal);

        // Accesses request based on user input
        // Comes from mapping (reuquests)
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.completed == false, "Request has already been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2, "Vote was not passed by contributors");

        // Defined recipient of the given request will be transferred the value specified
        thisRequest.recipient.transfer(thisRequest.value); 
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);

    } 

}