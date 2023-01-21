// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2.0;

contract EncodeNDecode {
    function getId(address x, uint256 e) public pure returns(uint256){
        bytes32 temp1 = bytes32(uint256(uint160(x)))<<(4*24); //24칸 우측 시프트
        bytes32 temp2 = bytes32(e<<(4*21)); //21칸 우측 시프트
        uint256 result = uint256(temp1 | temp2);
        return result;
    }
    
    function getAddress(uint256 id) public pure returns(address) {
        bytes32 temp1 = bytes32(id)>>(4*24);
        address result = address(uint160(uint256(temp1)));
        return result;   
    }

    function getEdition(uint256 id) public pure returns(uint256){
        bytes32 result = (bytes32(id)<<(4*40))>>(4*61);
        return uint256(result);
    }
}