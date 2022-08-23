// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0.0;

import "./SellerContract.sol";

contract SettlementContract {
    uint256 public _price;
    uint256 public cumulativeSales = 0;
    address public owner;
    bytes32 public keccak256Hash;
    bytes32 public songCid;
    
        
    mapping (address => copyrightHolder) public copyrightHolders;
    struct copyrightHolder {
        uint256 proportion;
        uint256 count;
    }

    event logBuyerInfo(address buyer, bytes32 songCid, uint256 amount);
    function buy() public payable {
        require(
            _price == msg.value &&
            msg.value % 10000 == 0 &&
            cumulativeSales < type(uint256).max //prevent overflow
        );
        cumulativeSales += 1;
        //구매자 기록            
        emit logBuyerInfo(msg.sender, songCid, _price);
    }

    event logRecieverInfo(address reciever, bytes32 songCid, uint256 amount);
    function settle() public {
        copyrightHolder memory caller = copyrightHolders[msg.sender];
        require(
            caller.proportion > 0 &&
            cumulativeSales - caller.count > 0 &&
            cumulativeSales < type(uint256).max
        );

        uint amount = _price / 10000 * caller.proportion * (cumulativeSales - caller.count);
        caller.count = cumulativeSales;
        payable(msg.sender).transfer(amount);
        emit logRecieverInfo(msg.sender, songCid, amount);
    }

    function destroy() public {
        require(msg.sender == owner && 
        address(this).balance < _price);
        selfdestruct(payable(owner));
    }

    constructor(address scAddress, address[] memory _addresses, uint256[] memory _proportions, bytes32 _songCid, uint256 price_) {  
        owner = SellerContract(scAddress).contractInitatorAddress();
        keccak256Hash = keccak256(abi.encode(_addresses, _proportions));
        songCid = _songCid; 
        _price = price_;
        for(uint i=0; i<_addresses.length; i++) {
            copyrightHolders[_addresses[i]] = copyrightHolder(_proportions[i], 0); 
        }
    }
}
