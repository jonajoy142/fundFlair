// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.5.0 < 0.9.0;

contract CroudFunding{
    mapping(address=>uint) contributors;
    address public manager;
    uint public deadline;
    uint public target;
    uint public minContribution;
    uint public noOfContributors;
    uint public raisedAmt;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool)voters;
    }
    mapping(uint=>Request)public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
        manager = msg.sender;   
    }

    function sendEth() public payable{
        require(block.timestamp < deadline,'deadline passed');
        require(msg.value >= minContribution,"minimum contribution not met");

        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmt += msg.value;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp > deadline, 'not eligible');
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }
    modifier onlyManager(){
        require(msg.sender == manager,"only manager can call this funcnction");
        _;
    }
    function createRequests(string memory _description, address payable _recipient, uint _value ) public onlyManager{
       Request storage newRequest = requests[numRequests];
       numRequests++;
       newRequest.description = _description;
       newRequest.recipient = _recipient;
       newRequest.value = _value;
       newRequest.completed = false;
       newRequest.noOfVoters = 0;
    }
    function voteRequest(uint _reqNo) public{
       require(contributors[msg.sender] > 0 , 'You are not a contributor');
       Request storage thisRequest = requests[_reqNo];
       require(thisRequest.voters[msg.sender]==false, 'You have already voted');
       thisRequest.voters[msg.sender] = true;
       thisRequest.noOfVoters++;
    }
     function reqPayment(uint _reqNo) public onlyManager{
        require(raisedAmt >= target,'Target not met');
        Request storage thisRequest = requests[_reqNo];
        require(thisRequest.completed == false, 'Request already completed');
        require(thisRequest.noOfVoters > noOfContributors/2, 'Not enough votes');
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }

}