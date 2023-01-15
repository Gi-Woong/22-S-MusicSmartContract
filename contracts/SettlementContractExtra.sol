// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SettlementContractExtra is ERC1155{
    uint256 public price;
    uint256 public cumulativeSales = 0;
    address public owner;
    bytes32 public keccak256Hash;
    bytes32[2] public songCid;

    mapping (address => uint256) public copyrightHolders;
    mapping (address => mapping(uint256 => sellData)) sellDatas; //seller => id => sellData
    
    struct sellData {
        uint256 tokenCount;
        uint256 price;
    }

    event logBuyerInfo(address buyer, bytes32[2] songCid, uint256 amount);
    function buySong() public payable {
        require(
            price == msg.value &&   
            cumulativeSales < type(uint256).max //prevent overflow
        );
        cumulativeSales += 1;
        //구매자 기록            
        emit logBuyerInfo(msg.sender, songCid, price);
    }

    function balanceOfMe() public view returns(uint256){
        return balanceOf(msg.sender, uint256(uint160(msg.sender)));
    }

    function checkIds(uint256[] memory ids) public view returns(bool) {
        address[] memory _addresses;
        for (uint i=0; i<ids.length; i++) {
            _addresses[i] = address(uint160(ids[i]));
        }
        return (keccak256(abi.encode(ids)) == keccak256Hash);
    }

    event logRecieverInfo(address reciever, bytes32[2] songCid, uint256 amount) ;
    function settleSong(uint256[] memory ids) public {
        require(checkIds(ids), "incorrect id inputs!");
        uint256 count = copyrightHolders[msg.sender];
        uint256 balance = 0;
        for (uint i=0; i<ids.length; i++) {
            balance += balanceOf(msg.sender, ids[i]);
        }
        require(
            balance > 0 &&
            cumulativeSales - count > 0 &&
            cumulativeSales < type(uint256).max
        );
        uint256 amount = price / 10000 * balance * (cumulativeSales - count);
        copyrightHolders[msg.sender] = cumulativeSales;
        payable(msg.sender).transfer(amount);   
        emit logRecieverInfo(msg.sender, songCid, amount);
    }


    function sellFT(uint256 _price, uint256 _id, uint256 cnt) public {
        require(balanceOf(msg.sender, _id) > 0); //토큰 개수가 1개 이상이여야 함
        require(balanceOf(msg.sender, _id) <= cnt);
        require(_price * cnt % 10 == 0); //10으로 나누어떨어져야 함
        sellDatas[msg.sender][_id].tokenCount = cnt;
        setApprovalForAll(address(this), true);
    }

    function buyFT(address from, uint256 _id) public payable{
        require(balanceOf(from, _id) > 0);
        require(msg.value >= sellDatas[from][_id].price, "balance is not enough.");
        this.safeTransferFrom(from, msg.sender, _id, sellDatas[from][_id].tokenCount, "");
        // sellDatas[from][_id].tokenCount = 0;
        setApprovalForAll(address(this), false); 
        copyrightHolders[from] = cumulativeSales;
        copyrightHolders[msg.sender] = cumulativeSales;

        uint256 loyalty = msg.value / 10;
        address minter = address(uint160(_id));
        payable(minter).transfer(loyalty);
        payable(from).transfer(msg.value - loyalty);
    }

    function myId() public view returns(uint256) {
        return uint256(uint160(msg.sender));
    }

    function destroy() public {
        require(msg.sender == owner && 
        address(this).balance < price);
        selfdestruct(payable(owner));
    }

    constructor(address[] memory _addresses, uint256[] memory _proportions, bytes32[2] memory _songCid, uint256 _price) ERC1155("") {  
        require(_price % 10000 == 0);
        owner = msg.sender;
        keccak256Hash = keccak256(abi.encode(_addresses)); // checkIds 때문에 proportion 빠짐. balanceOf()로 proportions도 검증 가능.
        songCid = _songCid; 
        price = _price;
        for(uint i=0; i<_addresses.length; i++) {
            _mint(_addresses[i], uint256(uint160(_addresses[i])), _proportions[i], "");
        }
    }
}
