// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

contract BuyerContract {
    address public buyerAddress;
    uint public musicId; //음원 id
    // uint public buyerContractDate;

    event logAddress(address _address);

    constructor(address _address, uint _musicId) {
        buyerAddress = _address;
        musicId = _musicId;
        // buyerContractDate = block.timestamp;
        emit logAddress(buyerAddress);
    }
}