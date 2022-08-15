// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract Buyer {
    address public buyerAddress;
    uint public wantToBuy; //음원 id
    uint public buyerContractDate;

    event log(address _address);

    constructor(address _address, uint toBuy) {
        buyerAddress = _address;
        wantToBuy = toBuy;
        buyerContractDate = block.timestamp;
        emit log(buyerAddress);
    }
}

contract Uploader {
    address public uploaderAddress;
    uint public uploadSong;
    uint public songPrice;
    uint public uploaderContractDate;

    event log(address _address);

    constructor(address _address, uint toUpload, uint price) {
        uploaderAddress = _address;
        uploadSong = toUpload;
        songPrice = price;
        uploaderContractDate = block.timestamp;
        emit log(uploaderAddress);
    }
}

contract Contract {
    Buyer buyer;
    Uploader uploader;

    bool alreadySetBuyer = false;
    bool alreadySetUploader = false;

    function setBuyer(uint songId) public {
        require(!alreadySetBuyer, "alreadySetBuyer");
        buyer = new Buyer({
            _address: msg.sender,
            toBuy: songId
        });
        alreadySetBuyer = true;
    }

    function setUploader(uint songId, uint songPrice) public {
        require(!alreadySetUploader, "!alreadySetUploader");
        uploader = new Uploader({
            _address: msg.sender,
            toUpload: songId,
            price: songPrice
        });
        alreadySetUploader = true;
    }

    modifier mustCheck() {
        require(buyer.wantToBuy() == uploader.uploadSong(), "buyer.wantToBuy() != uploader.uploadSong()");
        _;
    }

    function buyerSendMoney(uint amount) public payable mustCheck() {
        require(msg.sender == buyer.buyerAddress(), "msg.sender != buyer.buyerAddress()");
        require(msg.sender.balance > amount, "msg.sender.balance <= amount");
        require(amount == uploader.songPrice(), "amount != uploader.songPrice()");
        require(amount == msg.value, "amount != msg.value");
        require(amount == address(this).balance, "amount != address(this).balance");
    }

    function withdrawToUploader(uint amount) public payable mustCheck() {
        require(msg.sender == uploader.uploaderAddress(), "msg.sender != uploader.uploaderAddress()");
        require(amount == uploader.songPrice(), "amount != uploader.songPrice()");
        require(address(this).balance > 0, "address(this).balance <= 0" ); //0원일 때 호출 방지
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

}

