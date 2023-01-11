// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

import "./SettlementContractExtra.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

// 곡당 발행
// 원할 때 최초 발행 가능(?)
contract NFT1155 is ERC1155 {
    uint256 id = 1;
    address public settlementContract;
    mapping(uint256 => metadata) public metadatas; // id -> 
    struct metadata {
        uint256 price; // : must not be 0
        address minter; // : minter is authorship
        bool sell;
    }

    function isCopyrightHolder() internal view returns(bool) {
        uint256 p;
        (p, ) = SettlementContractExtra(settlementContract).copyrightHolders(msg.sender);
        if (p > 0) { return true; }
        else { return false; }
    }
    
    //원할 때 민팅
    //현재는 id 1개당 1개만 민팅 가능
    function mint(uint256 price) public{
        require(price > 0, "price must be upper than 0.");
        require(metadatas[id].price == 0, "Already minted token or zero price.");
        require(isCopyrightHolder(), "Not a copyrightHolder.");
        metadatas[id].price = price;
        _mint(msg.sender, id, 1, "");
        metadatas[id].minter = msg.sender;
        id++;
    }

    //특정 id type만 판매할 수 있도록 설정할 수 있어야 함.(완료)
    function sell(uint _id) public {
        require(isCopyrightHolder(), "Not a copyrightHolder(token owner).");
        metadatas[_id].sell = true;
        setApprovalForAll(address(this), true);
    }

    function buy(address _owner, uint256 _id) public payable {
        require(isApprovedForAll(_owner, address(this)) && metadatas[_id].sell, "Not Approved for selling.");
        require(msg.value >= metadatas[_id].price, "value is insufficient.");
        uint256 loyalty = msg.value / 10; //구매가의 10%를 로열티로 설정
        payable(_owner).transfer(msg.value - loyalty); //로열티 제외가 전송
        payable(metadatas[_id].minter).transfer(loyalty); //로열티 전송
        metadatas[id].price = msg.value; //구매가를 판매가로 지정
        this.safeTransferFrom(_owner, msg.sender, _id, 1, "");
        SettlementContractExtra(settlementContract).changeCopyrightHolder(_owner, _id, msg.sender);
        metadatas[_id].sell = false;
        setApprovalForAll(address(this), false);
    }

    constructor(string memory dirCid, address _contract) ERC1155(string(abi.encodePacked(string("https://ipfs.io/ipfs/"), dirCid, string("/{id}.json")))) {
        settlementContract = _contract;
        require(isCopyrightHolder(), "Not a copyrightHolder.");
        SettlementContractExtra(settlementContract).registerNftContract(msg.sender); 
        // mint();
    }
}
