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

    // TODO: 중복 정산 방지 해결책 마련 필요
    mapping (address => copyrightHolder) public copyrightHolders;
    struct copyrightHolder {
        uint256 proportion;
        uint256 count;
    }

    // TODO: 새로운 NFT contract를 생성해서 공격하는 경우를 막아야 함.
    // caller: NFT1155
    function registerNftContract(address _owner) public {
        address zeroAddress;
        require(nftContractAddress == zeroAddress, "already registered NFTContract.");
        require(copyrightHolders[_owner].proportion > 0, "not a CopyrightHolder.");
        require(NFT1155(msg.sender).settlementContract() == address(this), "Not a matching NFT contract.");
        nftContractAddress = msg.sender;
    }
    
    //함수 실행자: NFT1155
    //seller: 토큰 판매자 주소
    function changeCopyrightHolder(address prevCopyrightHolder, uint256 id, address newCopyrightHolder) public {
        require(nftContractAddress == msg.sender, "not matching NFTcontract!");
        require(NFT1155(msg.sender).settlementContract() == address(this), "not matching NFT contract!");
        require(NFT1155(msg.sender).balanceOf(newCopyrightHolder, id) >= 1, "not a NFT owner");
        copyrightHolder memory temp = copyrightHolders[prevCopyrightHolder];
        copyrightHolders[prevCopyrightHolder] = copyrightHolder(0, 0);
        copyrightHolders[newCopyrightHolder] = temp;
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