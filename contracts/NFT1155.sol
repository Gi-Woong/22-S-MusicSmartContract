// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./SettlementContractExtra.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

// 곡당 발행
contract NFT1155 is ERC1155 {
    address public settlementContract;
    string public dir;
    mapping(uint256 => sellData) public sellDatas;
    struct sellData {
        uint256 price; // : must not be 0
        uint256 amount;
        bool sell;
    }

    function isCopyrightHolder() internal view returns(bool) {
        uint256 p;
        (p, ) = SettlementContractExtra(settlementContract).copyrightHolders(msg.sender);
        require(p > 0, "Not a CopyrightHolder.");
        return true;
    }

    function getMintable() internal view returns(uint256) {
        uint256 p;
        (p, ) = SettlementContractExtra(settlementContract).copyrightHolders(msg.sender); 
        return p;
    }

    function tokenId(address _owner) internal pure returns(uint256){
        return uint256(uint160(_owner));
    }
    
    function mint() public{
        require(isCopyrightHolder(), "Not a copyrightHolder.");
        require(balanceOf(msg.sender, tokenId(msg.sender))==0, "already minted token");
        _mint(msg.sender, tokenId(msg.sender), getMintable(), "");   
        // id++;
    }

    function sell(uint256 price, uint256 _amount) public {
        require(isCopyrightHolder());
        uint256 _id = tokenId(msg.sender);
        sellDatas[_id].price = price;
        sellDatas[_id].amount = _amount;
        sellDatas[_id].sell = true;
        setApprovalForAll(address(this), true);
    }

    function buy(address _owner, uint256 _amount) public payable {
        uint256 _id = tokenId(_owner);
        require(isApprovedForAll(_owner, address(this)) && sellDatas[_id].sell, "Not Approved for selling.");
        require(msg.value >= sellDatas[_id].price, "value is insufficient.");
        uint256 loyalty = msg.value / 10; //구매가의 10%를 로열티로 설정
        payable(_owner).transfer(msg.value - loyalty); //로열티 제외가 전송
        payable(address((uint160(_id)))).transfer(loyalty); //로열티 전송
        this.safeTransferFrom(_owner, msg.sender, _id, _amount, "");
        SettlementContractExtra(settlementContract).changeCopyrightHolder(_owner, _amount, msg.sender);
        if (sellDatas[_id].amount == 0) {
            sellDatas[_id].sell = false;
            setApprovalForAll(address(this), false);
        }
    }

    function uri(uint256 _id) override public view returns (string memory) {
        return string(abi.encodePacked(dir, string("/"), string(abi.encode(_id)), string(".json")));
    }

    function register() public {
        SettlementContractExtra(settlementContract).registerNftContract(msg.sender); 
    }

    constructor(string memory _dir, address _contract) ERC1155(string(abi.encodePacked(_dir, string("/{id}.json")))) {
        settlementContract = _contract;
        require(isCopyrightHolder());
        dir = _dir;
    }
}
