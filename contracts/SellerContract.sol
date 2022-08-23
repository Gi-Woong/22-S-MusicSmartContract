// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

import "./SettlementContract.sol";

contract SellerContract {

    address public contractInitatorAddress; // contract 생성자 주소
    bytes32 public userId;

    // 생성자
    constructor(bytes32 _userId ) {
        userId = _userId;
        contractInitatorAddress = msg.sender;
    }
}