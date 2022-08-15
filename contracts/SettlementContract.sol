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

contract Seller {
    address public uploaderAddress;
    address[] private sellerAddresses;
    uint[] private proportion; 
    address private contractCallerAddress;
    uint public uploadedSong;
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

// 재사용 가능 컨트렉트

contract MusicContract {
    Buyer buyer;
    Seller seller;

    address owner;
    uint contractDate;

    bool private alreadySetBuyer = false;
    bool private alreadySetSeller = false;
    bool contractEnd = false;
    uint private index = 0;    

    modifier mustCheck() {
        require(buyer.wantToBuy() == seller.uploadedSong(), "buyer.wantToBuy() != seller.uploadedSong()");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function.");
        _;
    }

    modifier modSetSeller() {
        require(!alreadySetSeller, "alreadySetSeller");
        _;
        alreadySetSeller = true;
    } 
    
    modifier modSetBuyer() {
        require(!alreadySetBuyer, "alreadySetBuyer");
        contractEnd = false;
        _;
        alreadySetBuyer = true;
    }

    modifier modBuyerSendMoney(uint amount) {
        require(amount%10000 == 0, "amount%10000 != 0");
        require(msg.sender == buyer.buyerAddress(), "msg.sender != buyer.buyerAddress()");
        require(msg.sender.balance > amount, "msg.sender.balance <= amount");
        require(amount == seller.songPrice(), "amount != seller.songPrice()");
        require(amount == msg.value, "amount != msg.value");
        // require(amount == address(this).balance, "amount != address(this).balance");
        _;
        require(address(this).balance == seller.songPrice(), "!address(this).balance == seller.songPrice");
    }

    modifier modWithdrawToSeller() {
        require(!contractEnd, "contractEnd.");
        //require(msg.sender == seller.uploaderAddress(), "msg.sender != seller.sellerAddresses()");
        // require(address(this).balance > 0, "address(this).balance <= 0" ); //0원일 때 호출 방지
        _;
    }

    function setSeller(
        address[] memory addresses, uint[] memory proportions, uint songId, uint songPrice) public modSetSeller() {
        
        seller = new Seller({
            _uploaderAddress: msg.sender,
            _addresses: addresses,
            _proportions: proportions,
            toUpload: songId,
            price: songPrice
        });
        // 백엔드에서 업로드시 check해줄거기 때문에 
        // proportion의 합이 10000인지 체크하지 않아도 됨.
    }

    function setBuyer(uint songId) public modSetBuyer() {
        buyer = new Buyer({
            _address: msg.sender,
            toBuy: songId
        });
    }

    function buyerSendMoney(uint amount) public payable mustCheck() modBuyerSendMoney(amount){}

    function withdrawToSeller() public payable mustCheck() modWithdrawToSeller()  {
        address reciever = seller.getsellerAddresses()[index];
        payable(reciever).transfer(seller.songPrice() / 10000 * seller.getProportion()[index]);
        index++;
        if (index >= seller.getsellerAddresses().length) {
            index = 0;
            if(seller.songPrice() > 0)
                require(address(this).balance % seller.songPrice() == 0, "something Wrong.");
            contractEnd = true;
            alreadySetBuyer = false;
        }
    }

    // function withdrawByowner() public payable mustCheck() {
    //     require(msg.sender == owner, "Only owner can call this function.");
    //     payable(msg.sender).transfer(address(this).balance);
    // }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function destroy() public onlyOwner() {
        selfdestruct(payable(owner));
    }

    constructor() { 
        owner = msg.sender; 
        contractDate = block.timestamp;
    }
}

