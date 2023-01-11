// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./SettlementContractExtra.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

// 곡당 발행
contract FT1155 is ERC1155 {
    uint256 public constant tokenId = 0;
    address public owner;
    uint256 sellcnt = 0;
    uint256 price = 0;

    function sell(uint256 cnt, uint256 _price) public {
        require(owner == msg.sender, "not an owner.");
        sellcnt += cnt;
        price = _price;
        setApprovalForAll(address(this), true);
    }

    function buy(uint256 cnt) public payable {
        require(msg.sender!=owner);
        payable(owner).transfer(price * cnt);
        this.safeTransferFrom(owner, msg.sender, tokenId, cnt, "");
        sellcnt -= cnt;
    }
    
    constructor(address _contract) ERC1155("") {    
        uint256 p;
        (p, ) = SettlementContractExtra(_contract).copyrightHolders(msg.sender);
        require(p > 0, "not a copyrightHolder");
        _mint(msg.sender, tokenId, p, "");
        owner = msg.sender;
        SettlementContractExtra(_contract).registerFtAddress();
        // proportion 0으로 만들기

    }
}