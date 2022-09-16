// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

contract SettlementContract {
    uint256 public price;
    uint256 public cumulativeSales = 0;
    address public owner;
    bytes32 public keccak256Hash;
    bytes32[2] public songCid; 

    mapping (address => copyrightHolder) public copyrightHolders;
    struct copyrightHolder {
        uint256 proportion;
        uint256 count;
    }

    event logBuyerInfo(address buyer, bytes32[2] songCid, uint256 amount);
    function buy() public payable {
        require(
            price == msg.value &&
            msg.value % 10000 == 0 &&
            cumulativeSales < type(uint256).max //prevent overflow
        );
        cumulativeSales += 1;
        //구매자 기록            
        emit logBuyerInfo(msg.sender, songCid, price);
    }

    event logRecieverInfo(address reciever, bytes32[2] songCid, uint256 amount);
    function settle() public {
        copyrightHolder memory caller = copyrightHolders[msg.sender];
        require(
            caller.proportion > 0 &&
            cumulativeSales - caller.count > 0 &&
            cumulativeSales < type(uint256).max
        );

        uint amount = price / 10000 * caller.proportion * (cumulativeSales - caller.count);
        caller.count = cumulativeSales;
        payable(msg.sender).transfer(amount);
        emit logRecieverInfo(msg.sender, songCid, amount);
    }

    function destroy() public {
        require(msg.sender == owner && 
        address(this).balance < price);
        selfdestruct(payable(owner));
    }

    constructor(address[] memory _addresses, uint256[] memory _proportions, bytes32[2] memory _songCid, uint256 _price) {  
        owner = msg.sender;
        keccak256Hash = keccak256(abi.encode(_addresses, _proportions));
        songCid = _songCid; 
        price = _price;
        for(uint i=0; i<_addresses.length; i++) {
            copyrightHolders[_addresses[i]] = copyrightHolder(_proportions[i], 0); 
        }
    }
}
 