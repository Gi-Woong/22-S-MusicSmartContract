// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./NFT1155.sol";

contract SettlementContractExtra {
    uint256 public price;
    uint256 public cumulativeSales = 0;
    address public owner;
    bytes32 public keccak256Hash;
    bytes32[2] public songCid;
    address public nftContractAddress;

    mapping (address => copyrightHolder) public copyrightHolders;
    struct copyrightHolder {
        uint256 proportion;
        uint256 count;
    }

    // caller: NFT1155
    function registerNftContract(address _owner) public {
        address zeroAddress;
        require(nftContractAddress == zeroAddress, "already registered NFTContract.");
        require(copyrightHolders[_owner].proportion > 0, "not a CopyrightHolder.");
        require(NFT1155(msg.sender).settlementContract() == address(this), "Not a matching NFT contract.");
        nftContractAddress = msg.sender;
    }

    //caller: NFT1155
    function changeCopyrightHolder(address prev, uint256 _amount, address _new) public {
        require(nftContractAddress == msg.sender, "not matching NFT contract!");
        require(NFT1155(msg.sender).settlementContract() == address(this), "settlementContractAddress is not matching!");
        // uint256 balance = NFT1155(msg.sender).balanceOf(_new, uint256(uint160(prev)));
        // require( balance >= 1, "not a NFT owner!");
        copyrightHolders[prev] = copyrightHolder(copyrightHolders[prev].proportion - _amount, 0);
        copyrightHolders[_new] = copyrightHolder(copyrightHolders[_new].proportion + _amount, 0);
    }

    /////////////////////////////////////////////

    event logBuyerInfo(address buyer, bytes32[2] songCid, uint256 amount);
    function buy() public payable {
        require(
            price == msg.value &&
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
        copyrightHolders[msg.sender].count = cumulativeSales;
        payable(msg.sender).transfer(amount);
        emit logRecieverInfo(msg.sender, songCid, amount);
    }

    function destroy() public {
        require(msg.sender == owner && 
        address(this).balance < price);
        selfdestruct(payable(owner));
    }

    constructor(address[] memory _addresses, uint256[] memory _proportions, bytes32[2] memory _songCid, uint256 _price) {  
        require(_price % 10000 == 0);
        owner = msg.sender;
        keccak256Hash = keccak256(abi.encode(_addresses, _proportions));
        songCid = _songCid; 
        price = _price;
        for(uint i=0; i<_addresses.length; i++) {
            copyrightHolders[_addresses[i]] = copyrightHolder(_proportions[i], 0); 
        }
        require(copyrightHolders[owner].proportion > 0, "not a CopyrightHolder");
    }
}
