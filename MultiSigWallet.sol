
//SPDX-License-Identifier:MIT

pragma solidity ^0.8.5;


contract AccessControl{
    
    address internal ADMIN;
    
    constructor(){
        ADMIN = msg.sender; // One who is deploying contract is ADMIN
    }
}

contract MultisigWallet is AccessControl{
    
    modifier onlyOwners {
        if (msg.sender == ADMIN) {
            _;
        }
        else {
            for (uint i =0 ; i < ownersList.length ; i++) {
                if (msg.sender == ownersList[i]) {
                    _;
                    break;
                }
            }
        }
    }
    
    modifier onlyAdmin {
        require(msg.sender == ADMIN);
        _; 
    }

    mapping(address => bool) internal ownersMap;
    mapping(address => uint) internal ownersIdMap; 
    address[] internal ownersList;
    uint internal ownersNum = 0;

    
    //mapping (address => uint) deposits; // just to know how much anyone added
    

    uint public approvalsNeeded;

    struct RequestData {
        address recipient;
         uint amount;
         uint approvals;
    } 

    RequestData[] transferRequests;
    mapping(uint => address[]) approvers;

    //events
    event depositDone(uint amount, address depositedFrom);
    event transferRequestCreated(uint requestId);
    event fundsTransferred(address recipient, uint amount);
    

    
    function addOwners(address _newOwner) public onlyAdmin{
        require(!ownersMap[_newOwner],"Already added");
        ownersMap[_newOwner] = true;
        ownersIdMap[_newOwner] = ownersList.length;
        ownersList.push(_newOwner);
        ownersNum += 1;
    }

    function removeOwner(address _fallenOwner) public onlyAdmin {
        require(ownersMap[_fallenOwner],"Not Owner");
        ownersMap[_fallenOwner] = false;
        delete ownersList[ownersIdMap[_fallenOwner]];
        ownersNum -= 1;
    }

    function deposit() public payable {
        emit depositDone(msg.value, msg.sender);
    }
    
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    } 

    function getOwners() public view returns (address[] memory) {
        return ownersList;
    }
    
    function createTransferRequest(address _recipient, uint _amount) public onlyOwners {        
        transferRequests.push(RequestData(_recipient, _amount, 1));
        uint id = transferRequests.length-1;
        approvers[id].push(msg.sender);
        emit transferRequestCreated(id);
    }

    function calculateApprovalsNeeded() public {
        
        approvalsNeeded =  ((ownersNum *60)/100); //only consider integral part of result   
    }

    function getApprovers(uint _id) public view returns(address[] memory) {
        return (approvers[_id]);
    }

    function getTransferRequests() public view returns (RequestData[] memory){
        return transferRequests;
    }

    function approve(uint _id) public onlyOwners {
        

        bool notApprovedBySender = true;
        for (uint i = 0; i < approvers[_id].length; i++) {            
            if (approvers[_id][i] == msg.sender) {
              notApprovedBySender = false;
              break;  
            }   
        }

        if (notApprovedBySender) {
            approvers[_id].push(msg.sender);
            transferRequests[_id].approvals++;
        }

        if (transferRequests[_id].approvals >= approvalsNeeded) {
            _transfer(transferRequests[_id].recipient, transferRequests[_id].amount);
        }
    }

    function _transfer(address _recipient, uint _amount) private {
        payable(_recipient).transfer(_amount);
        emit fundsTransferred(_recipient, _amount);
    }

    
}  
    

