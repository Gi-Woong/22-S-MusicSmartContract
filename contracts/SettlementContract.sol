// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

import "./SellerContract.sol";

contract SettlementContract {
    SellerContract public seller;

    address private owner; //정상적이라면 seller가 됨.
    bool private alreadySetBuyer = false; //거래가 끝날 때까지 true
    bool private alreadySetSeller = false; //한번 등록하면 영원히 true
    bool private contractEnd = false; //거래 종료 여부
    address[] private sellerAddresses; // 판매자(정산자) 지갑 주소
    uint[] private proportion; // 곡 정산 비율
    // uint public contractDate;

    // 구매자
    address public buyerAddress;
    uint public buyerMusicId; //음원 id

    modifier mustCheck() {
        require(!contractEnd, "contractEnd.");
        require(buyerMusicId == seller.uploadedSong(), "buyer.wantToBuy() != seller.uploadedSong()");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == address(this), "Only Owner can call this function.");
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
        require(msg.sender == buyerAddress, "msg.sender != buyer.buyerAddress()");
        require(msg.sender.balance > amount, "msg.sender.balance <= amount");
        require(amount == seller.songPrice(), "amount != seller.songPrice()");
        require(amount == msg.value, "amount != msg.value");
        require(address(this).balance == seller.songPrice(), "!address(this).balance != seller.songPrice");
        _;
        require(address(this).balance <= 0, "error");
    }

    // 주소 접근 방지
    modifier modAfterContstruct(address msgsender) {
        require(msgsender == address(seller), "msgsender != address(seller)");
        _;
    }

    function setBuyer(uint songId) public modSetBuyer() {
        require(songId == seller.uploadedSong());
        buyerMusicId = songId;
        buyerAddress = msg.sender;
    }

    function buyerSendMoney(uint amount) public payable mustCheck() modBuyerSendMoney(amount){
        //송금 즉시 분배
        for (uint i=0; i < sellerAddresses.length; i++) {
            address reciever = sellerAddresses[i];
            payable(reciever).transfer(seller.songPrice() / 10000 * proportion[i]);
        }            
        endContract();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function endContract() private {
        if(seller.songPrice() > 0) //거래 잔액이 0이 아니라면
                require(address(this).balance % seller.songPrice() == 0, "something Wrong. The contract still have some money");
        contractEnd = true;
    }

    function destroy() public onlyOwner() {
        contractEnd = true;
        selfdestruct(payable(owner));
    }

    //공개 범위는 public이지만 SellerContract만 실행할 수 있음
    function afterConstruct() public modAfterContstruct(msg.sender) {
        sellerAddresses = seller.getsellerAddresses();
        proportion = seller.getProportion();
    } 

    constructor() { 
        owner = msg.sender; 
        // contractDate = block.timestamp;
        seller = SellerContract(msg.sender); //호출자의 주소를 Seller contract로 casting
    }
}

