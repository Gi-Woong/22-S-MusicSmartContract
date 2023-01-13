// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

// import "./NFT1155.sol";
import "./FT1155.sol";

contract SettlementContractExtra {
    uint256 public price;
    uint256 public cumulativeSales = 0;
    address public owner;
    bytes32 public keccak256Hash;
    bytes32[2] public songCid;
    // address public nftContractAddress;

    mapping (address => copyrightHolder) public copyrightHolders;
    struct copyrightHolder {
        uint256 proportion;
        uint256 count;
    }
    mapping (address => address) registered;

    function registerFtAddress() public {
        address ftMinter = FT1155(msg.sender).owner(); 
        require(copyrightHolders[ftMinter].proportion > 0, "not a copyrightHolder");
        require(registered[ftMinter] == address(0), "already registered.");
        registered[ftMinter] = msg.sender;
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
        require(registered[msg.sender] == address(0), "already registered FT. call settleByFT() function.");
        copyrightHolder memory caller = copyrightHolders[msg.sender];
        require(
            caller.proportion > 0 &&
            cumulativeSales - caller.count > 0 &&
            cumulativeSales < type(uint256).max
        );
        uint256 amount = price / 10000 * caller.proportion * (cumulativeSales - caller.count);
        copyrightHolders[msg.sender].count = cumulativeSales;
        payable(msg.sender).transfer(amount);
        emit logRecieverInfo(msg.sender, songCid, amount);
    }

    function settleByFT(address[] memory ftAddresses) public {
        uint256 amount = 0;
        for(uint i=0; i<ftAddresses.length; i++) {
            address ftMinter = FT1155(ftAddresses[i]).owner();
            require(registered[ftMinter] == ftAddresses[i], "not registered.");
            uint256 balance = FT1155(ftAddresses[i]).balanceOf(msg.sender, FT1155(ftAddresses[i]).TOKEN_ID());
            require(balance >= 1, "not a FT owner.");
            amount += price / 10000 * balance * (cumulativeSales - copyrightHolders[ftMinter].count);
            copyrightHolders[ftMinter].count = cumulativeSales;
        }
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
