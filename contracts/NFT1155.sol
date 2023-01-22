// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./SettlementContractExtra.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

// 저작권자 1명당 1개 발행
contract NFT1155 is ERC1155 {
    address public settlementContract;
    address public minter;
    address public owner;
    string public dir;
    uint256 public price;
    uint256 public proportion;
    //tokenId = 0;

    function sell(uint256 _price) public {
        require(balanceOf(msg.sender, 0) > 0, "not NFT owner!");
        require(isCopyrightHolder());
        require(_price > 0, "price should larger than zero!");
        price = _price;
        setApprovalForAll(address(this), true);
    }

    function buy() public payable {
        require(msg.value >= price, "value is insufficient.");
        uint256 loyalty = msg.value / 10; //구매가의 10%를 로열티로 설정
        payable(owner).transfer(msg.value - loyalty); //로열티 제외가 전송
        payable(minter).transfer(loyalty); //로열티 전송
        this.safeTransferFrom(owner, msg.sender, 0, 1, "");
        SettlementContractExtra(settlementContract).changeCopyrightHolder(owner, msg.sender);
        owner = msg.sender;
        setApprovalForAll(address(this), false);
    }

    function isCopyrightHolder() public view returns(bool) {
        (uint256 p, ) = SettlementContractExtra(settlementContract).copyrightHolders(msg.sender);
        require(p > 0, "Not a CopyrightHolder.");
        return true;
    }

    function register() public {
        SettlementContractExtra(settlementContract).registerNftContract(msg.sender); 
    }

    constructor(string memory _dir, address _contract) ERC1155("") {
        settlementContract = _contract;
        require(isCopyrightHolder());
        minter = msg.sender;
        owner = msg.sender;
        (proportion, ) = SettlementContractExtra(_contract).copyrightHolders(msg.sender);
        _mint(msg.sender, 0, 1, "");
        dir = _dir;
    }
}
