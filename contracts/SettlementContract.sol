// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

import "./SellerContract.sol";

contract SettlementContract {
    SellerContract public sellerContract;

    address private owner; //정상적이라면 seller가 됨.
    address[] private sellerAddresses; // 판매자(정산자) 지갑 주소
    uint[] private proportion; // 곡 정산 비율
    bytes32 public keccak256Hash; // 클라이언트 확인용(?)
    // uint public contractDate;

    bool private contractDestroyed = false; // 거래 폐기 여부
        
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function.");
        _;
    }

    modifier modBuyerSendMoney(uint amount) {
        require(!contractDestroyed, "contract Destroyed.");
        require(amount % 10000 == 0, "amount%10000 != 0");
        require(msg.sender.balance > amount, "msg.sender.balance <= amount");
        require(amount == sellerContract.songPrice(), "amount != seller.songPrice()");
        require(amount == msg.value, "amount != msg.value");
        require(address(this).balance >= sellerContract.songPrice(), "!address(this).balance <= seller.songPrice");
        _;
    }

    // 주소 접근 방지
    modifier modAfterContstruct(address msgsender) {
        require(msgsender == address(sellerContract), "msgsender != address(seller)");
        _;
    }

    event logBuyerInfo(address buyerAddress, uint songId, uint amount);
    function buyerSendMoney(uint songId, uint amount) public payable modBuyerSendMoney(amount){
        require(songId == sellerContract.songId(), "buyer's songId != sellerContract.uploadedSong()");
        //송금 즉시 분배
        for (uint i=0; i < sellerAddresses.length; i++) {
            address reciever = sellerAddresses[i];
            payable(reciever).transfer(sellerContract.songPrice() / 10000 * proportion[i]);
        }
        //구매자 기록            
        emit logBuyerInfo(msg.sender, songId, amount);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 컨트렉트 소멸
    function destroy() public onlyOwner() {
        selfdestruct(payable(owner));
        contractDestroyed = true;
    }

    //공개 범위는 public이지만 SellerContract만 실행할 수 있음
    function afterConstruct() public modAfterContstruct(msg.sender) {
        // sellerAddresses = sellerContract.getsellerAddresses();
        // proportion = sellerContract.getProportion();
        // owner = sellerContract.getContractInitatorAddress();
        (sellerAddresses, proportion, owner) = sellerContract.getPrivateThings(); 
    } 

    constructor() {  
        // contractDate = block.timestamp;
        sellerContract = SellerContract(msg.sender); //호출자의 주소를 Seller contract로 casting
        keccak256Hash = sellerContract.keccak256Hash();// 해시값
    }
}