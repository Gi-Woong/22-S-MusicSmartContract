// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./SellerContract.sol";
import "./BuyerContract.sol";

contract SettlementContract {
    BuyerContract buyer;
    SellerContract seller;

    address private owner; //정상적이라면 seller가 됨.
    uint contractDate;

    bool private alreadySetBuyer = false; //거래가 끝날 때까지 true
    bool private alreadySetSeller = false; //한번 등록하면 영원히 true
    bool private contractEnd = false; //거래 종료 여부
    uint private index = 0; //정산 차례

    modifier mustCheck() {
        require(!contractEnd, "contractEnd.");
        require(buyer.musicId() == seller.uploadedSong(), "buyer.wantToBuy() != seller.uploadedSong()");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function.");
        _;
    }
    
    modifier modSetBuyer() {
        require(!contractEnd, "contractEnd.");
        require(!alreadySetBuyer, "alreadySetBuyer");
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

    function setBuyer(uint songId) public modSetBuyer() {
        buyer = new BuyerContract({
            _address: msg.sender,
            _musicId: songId
        });
    }

    function buyerSendMoney(uint amount) public payable mustCheck() modBuyerSendMoney(amount){}

    function settleToSeller() public payable mustCheck() {
        address reciever = seller.getsellerAddresses()[index];
        payable(reciever).transfer(seller.songPrice() / 10000 * seller.getProportion()[index]);
        index++;
        if (index >= seller.getsellerAddresses().length) { // 모두 정산 완료 했다면
            index = 0;
            if(seller.songPrice() > 0) //거래 잔액이 0이 아니라면
                require(address(this).balance % seller.songPrice() == 0, "something Wrong. The contract still have some money");
            contractEnd = true;
        }
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function destroy() public onlyOwner() {
        contractEnd = true;
        selfdestruct(payable(owner));
    }

    constructor() { 
        owner = msg.sender; 
        contractDate = block.timestamp;
        seller = SellerContract(msg.sender); //호출자의 주소를 Seller contract로 casting
    }
}

