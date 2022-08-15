// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./SettlementContract.sol";

contract SellerContract {
    address[] private sellerAddresses; // 판매자(정산자) 지갑 주소
    uint[] private proportion; // 곡 정산 비율
    uint public uploadedSong; //음원 id
    uint public songPrice; //곡 가격
    uint public sellerContractDate; // 거래 생성 일시
    address private contractCallerAddress; // contract 호출자 주소
    address settlementContractAddress;

    modifier checkAccesser(address msgsender) {
        require(msgsender == settlementContractAddress, "Only settlementContract owner can access.");
        _;
    }

    function getsellerAddresses() public view checkAccesser(msg.sender) returns(address[] memory) {
        return sellerAddresses;
    }
    function getProportion() public view checkAccesser(msg.sender) returns(uint[] memory) {
        return proportion;
    }

	event logContractAddress(address _address); //생성된 contract 주소 기록
    // Music Contract 생성함수
    function makeContract() public returns(address) {
        settlementContractAddress = address(new SettlementContract());
        emit logContractAddress(settlementContractAddress);
        return settlementContractAddress;
    }

    // 생성자
    constructor(address[] memory _addresses, uint[] memory _proportions, uint toUpload, uint price) {
        sellerAddresses = _addresses;
        proportion = _proportions;
        uploadedSong = toUpload;
        songPrice = price;
        sellerContractDate = block.timestamp;
        contractCallerAddress = msg.sender;
    }

}