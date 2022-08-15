// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

import "./SettlementContract.sol";

contract SellerContract {
    address[] private sellerAddresses; // 판매자(정산자) 지갑 주소
    uint[] private proportion; // 곡 정산 비율
    uint public songId; //음원 id
    uint public songPrice; //곡 가격
    // uint public sellerContractDate; // 거래 생성 일시
    address private contractInitatorAddress; // contract 호출자 주소
    address public settlementContractAddress; // 왜?)계약서 주소를 알아야 함.
    bool public madeContract;

    modifier checkAccesser(address msgsender) {
        require(msgsender == settlementContractAddress, "Only settlementContract can access.");
        _;
    }

    // // 접근 제어자는 public이지만 SettlementContractAddress만 접근할 수 있음
    // function getsellerAddresses() public view checkAccesser(msg.sender) returns(address[] memory) {
    //     return sellerAddresses;
    // }
    // // 접근 제어자는 public이지만 SettlementContractAddress만 접근할 수 있음
    // function getProportion() public view checkAccesser(msg.sender) returns(uint[] memory) {
    //     return proportion;
    // }
    // // 접근 제어자는 public이지만 SettlementContractAddress만 접근할 수 있음
    // function getContractInitatorAddress() public view checkAccesser(msg.sender) returns(address) {
    //     return contractInitatorAddress;
    // }

    // SettlementContract에서 쓸 함수
    //공개 범위는 public이지만 SettlementContract만 실행할 수 있음
    function getPrivateThings() public view checkAccesser(msg.sender) returns(address[] memory, uint[] memory, address) {
        return (sellerAddresses, proportion, contractInitatorAddress); 
    }

	event logSettlementContractAddress(address _address); //생성된 contract 주소 기록
    // Music Contract 생성함수
    function makeContract() public returns(address) {
        require(madeContract, "already made contract");
        SettlementContract settlementContract = new SettlementContract(); 
        settlementContractAddress = address(settlementContract);
        settlementContract.afterConstruct();
        emit logSettlementContractAddress(settlementContractAddress);
        madeContract = true;
        return settlementContractAddress;
    }

    // 생성자
    constructor(address[] memory _addresses, uint[] memory _proportions, uint _songId, uint price) {
        sellerAddresses = _addresses;
        proportion = _proportions;
        songId = _songId; // 변수명 수정
        songPrice = price;
        // sellerContractDate = block.timestamp;
        contractInitatorAddress = msg.sender;
    }

}