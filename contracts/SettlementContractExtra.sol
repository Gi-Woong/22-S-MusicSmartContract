// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./NFT1155.sol";

contract SettlementContractExtra {
    uint256 public price;
    uint256 public cumulativeSales = 0;
    address public owner;
    bytes32 public keccak256Hash;
    bytes32[2] public songCid;
    mapping (address => copyrightHolder) public copyrightHolders;
    mapping (address => address) public nftContractAddresses; // minter -> NFT1155
    struct copyrightHolder {
        uint256 proportion;
        uint256 count;
    }

    // caller: NFT1155
    function registerNftContract(address minter) public {
        require(NFT1155(msg.sender).minter() == minter, "Not NFT contract minter!"); // Function caller should be NFT1155.
        require(copyrightHolders[minter].proportion > 0, "Not a copyright holder!"); // Minter should be in a mapping of copyrightHolders.
        require(nftContractAddresses[minter] == address(0), "Already registered!");  // Contract should not be registered.
        nftContractAddresses[minter] = msg.sender;
    }
    
    //함수 실행자: NFT1155
    //seller: 토큰 판매자 주소
    function changeCopyrightHolder(address prev, address _new) public {
        require(nftContractAddresses[NFT1155(msg.sender).minter()] == msg.sender, "not a proper NFT Contract");
        require(NFT1155(msg.sender).balanceOf(_new, 0) >= 1, "not a NFT owner");
        copyrightHolder[2] memory holders = [copyrightHolders[prev], copyrightHolders[_new]];
        copyrightHolders[prev] = copyrightHolder(holders[0].proportion - NFT1155(msg.sender).proportion(), cumulativeSales);
        copyrightHolders[_new] = copyrightHolder(holders[0].proportion + holders[1].proportion, cumulativeSales);
        if (holders[0].count < cumulativeSales) {
            payable(prev).transfer(price / 10000 * holders[0].proportion * (cumulativeSales - holders[0].count));
        }
        if (holders[1].count < cumulativeSales) {
            payable(prev).transfer(price / 10000 * holders[1].proportion * (cumulativeSales - holders[1].count));
        }
    }

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