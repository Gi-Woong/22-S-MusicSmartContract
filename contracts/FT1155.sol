// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./SettlementContractExtra.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// 저작권자당 발행
contract FT1155 is ERC1155 {
    uint256 public constant TOKEN_ID = 0;
    address public owner;
    address public settlementContract;
    mapping (address => sellData) public sellDatas;
    struct sellData {
        uint256 sellcnt;
        uint256 price;
    }

    function sell(uint256 cnt, uint256 _price) public {
        sellData memory _sellData = sellDatas[msg.sender];
        require(cnt < balanceOf(msg.sender, TOKEN_ID) && cnt > 0, "cannot exceed owned token balance.");
        require(_sellData.price * cnt > 10, "invalid inputs.");
        sellDatas[msg.sender].sellcnt = cnt;
        sellDatas[msg.sender].price = _price;
        setApprovalForAll(address(this), true);
    }

    function buy(address seller, uint256 cnt) public payable {
        sellData memory _sellData = sellDatas[seller];
        require(balanceOf(seller, TOKEN_ID) >= 1 && _sellData.price >= 1, "not on sale.");
        require(_sellData.sellcnt > 0, "not consumable state.");
        require(msg.value == _sellData.price * cnt, "not proper value");
        uint256 loyalty = (_sellData.price * cnt) / 10; 
        payable(seller).transfer(msg.value - loyalty); // 10% 로열티 제외하고 전송
        payable(owner).transfer(loyalty); // 10% 로열티 전송
        
        this.safeTransferFrom(owner, msg.sender, TOKEN_ID, cnt, ""); // token 소유권 이전
        sellDatas[seller].sellcnt -= cnt; 
    }

    function register() public {
        SettlementContractExtra(settlementContract).registerFtAddress();
    }
    
    constructor(address _contract) ERC1155("") {    
        uint256 p;
        (p, ) = SettlementContractExtra(_contract).copyrightHolders(msg.sender);
        require(p > 0, "not a copyrightHolder");
        _mint(msg.sender, TOKEN_ID, p, "");
        owner = msg.sender;
        settlementContract = _contract;
    }
}