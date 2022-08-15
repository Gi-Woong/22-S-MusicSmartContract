// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
// 재사용 가능 컨트렉트

import "./Seller.sol";
import "./Buyer.sol";

contract MusicContract {
    Buyer buyer;
    Seller seller;

    address owner;
    uint contractDate;

    bool private alreadySetBuyer = false; //거래가 끝날 때까지 true
    bool private alreadySetSeller = false; //한번 등록하면 영원히 true
    bool private contractEnd = false; //거래 종료 여부
    uint private index = 0; //정산 차례

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
        _;
        require(address(this).balance == seller.songPrice(), "!address(this).balance != seller.songPrice");
    }

    modifier modWithdrawToSeller() {
        require(!contractEnd, "contractEnd.");
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

