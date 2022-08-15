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

contract CopyrightHolders {
    address public uploaderAddress;
    address[] public sellerAddresses;
    uint[] public proportion; 
    uint public uploadedSong;
    uint public sellerContractDate;
    uint public songPrice;

    function getsellerAddresses() public view returns(address[] memory) {
        return sellerAddresses;
    }
    function getProportion() public view returns(uint[] memory) {
        return proportion;
    }
}

contract Seller is CopyrightHolders {


    event log(address[] _address);
    constructor(address _uploaderAddress, address[] memory _addresses, uint[] memory _proportions, uint toUpload, uint price) {
        uploaderAddress = _uploaderAddress;
        sellerAddresses = _addresses;
        proportion = _proportions;
        uploadedSong = toUpload;
        songPrice = price;
        sellerContractDate = block.timestamp;
        emit log(sellerAddresses);
    }
}

contract Contract {
    Buyer buyer;
    Seller seller;

    address owner;
    uint ContractDate;

    bool private alreadySetBuyer = false;
    bool private alreadySetSeller = false;
    bool contractEnd = false;
    uint private index = 0;    

    modifier mustCheck() {
        require(buyer.wantToBuy() == seller.uploadedSong(), "buyer.wantToBuy() != seller.uploadedSong()");
        if (contractEnd)
            alreadySetBuyer = false;
        _;
    }

    modifier onlyOwner() {
        _;
    }

    function setSeller(address[] memory addresses, uint[] memory proportions, uint songId, uint songPrice) public {
        require(!alreadySetSeller, "alreadySetSeller");
        seller = new Seller({
            _uploaderAddress: msg.sender,
            _addresses: addresses,
            _proportions: proportions,
            toUpload: songId,
            price: songPrice
        });

        // for(uint i=0; i<addresses.length; i++) {
        //     isWithdrew[]
        // }
        // 백엔드에서 업로드시 check해줄거기 때문에 
        // proportion의 합이 10000인지 체크하지 않아도 됨.
        alreadySetSeller = true;
    }

    function setBuyer(uint songId) public {
        require(!alreadySetBuyer, "alreadySetBuyer");
        contractEnd = false;

        buyer = new Buyer({
            _address: msg.sender,
            toBuy: songId
        });
        alreadySetBuyer = true;
    }

    function buyerSendMoney(uint amount) public payable mustCheck() {
        require(amount%10000 == 0, "amount%10000 != 0");
        require(msg.sender == buyer.buyerAddress(), "msg.sender != buyer.buyerAddress()");
        require(msg.sender.balance > amount, "msg.sender.balance <= amount");
        require(amount == seller.songPrice(), "amount != seller.songPrice()");
        require(amount == msg.value, "amount != msg.value");
        // require(amount == address(this).balance, "amount != address(this).balance");
    }
    event log(address me);

    function withdrawToSeller() public payable mustCheck() {
        require(!contractEnd, "contractEnd.");
        //require(msg.sender == seller.uploaderAddress(), "msg.sender != seller.sellerAddresses()");
        // require(address(this).balance > 0, "address(this).balance <= 0" ); //0원일 때 호출 방지
        address reciever = seller.sellerAddresses(index);
        payable(reciever).transfer(address(this).balance);
        index++;
        if (index >= seller.getsellerAddresses().length) {
            index = 0;
            if(seller.songPrice() > 0)
                require(address(this).balance % seller.songPrice() == 0, "something Wrong.");
            contractEnd = true;
        }
    }

    // function withdrawByAdmin() public payable mustCheck() {
    //     require(msg.sender == admin, "Only admin can call this function.");
    //     payable(msg.sender).transfer(address(this).balance);
    // }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function destroy() public {
        require(msg.sender == owner, "Only Owner can call this function.");
        selfdestruct(payable(owner));
    }

    constructor() { 
        owner = msg.sender; 
        ContractDate = block.timestamp;
    }
}

