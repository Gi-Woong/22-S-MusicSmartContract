// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract Seller {
    address public uploaderAddress;
    address[] private sellerAddresses;
    uint[] private proportion; 
    address private contractCallerAddress;
    uint public uploadedSong; //음원 id
    uint public sellerContractDate;
    uint public songPrice;

    modifier callerCheck(address sender) {
        require(contractCallerAddress == sender, "contractCallerAddress != sender");
        _;
    }
    
    function getsellerAddresses() public view callerCheck(msg.sender) returns(address[] memory) {
        return sellerAddresses;
    }
    function getProportion() public view callerCheck(msg.sender) returns(uint[] memory) {
        return proportion;
    }  
    // event log(address[] _address);
    constructor(address _uploaderAddress, address[] memory _addresses, uint[] memory _proportions, uint toUpload, uint price) {
        uploaderAddress = _uploaderAddress;
        sellerAddresses = _addresses;
        proportion = _proportions;
        contractCallerAddress = msg.sender;
        uploadedSong = toUpload;
        songPrice = price;
        sellerContractDate = block.timestamp;
        // emit log(sellerAddresses);
    }
}