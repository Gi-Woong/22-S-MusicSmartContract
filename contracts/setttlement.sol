// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
// 곡 단위로 구매자가 구매시 정산 진행
contract Settlement {
    struct songMetaData {        
        // 한 곡당 구매가격
        uint gweiPerBuy;
        // 권리자 id(uint)
        uint[] id;
        // 권리자 지갑 address
        address[] _address;
        // (음원에 대한 저작권 비율. 최대 100%=>100,00)
        uint[] proportion;
    }

    event log(bytes);
    event log(uint);

    mapping(uint => songMetaData) payProperty;
    
    address admin;

    //// 음원 업로드시 수행해야 할 부분
    // 곡의 정산에 필요한 정보를 생성하는 함수
    function createsongMetaData(uint _songId, uint _gweiPerBuy) public {
        // 초기화
        payProperty[_songId] = songMetaData({
            gweiPerBuy: _gweiPerBuy,
            id: new uint[](0),
            _address: new address[](0),
            proportion: new uint[](0)
        });
    }
    
    // 저작자 정보를 추가하는 함수
    function addsongRightHolder(uint songId, uint id, address _address, uint proportion) public {
        require(proportion<=10000, "rightProportion must be less than or equal to 10000");
        songMetaData storage sM = payProperty[songId];
        sM.id.push(id);
        sM._address.push(_address);
        sM.proportion.push(proportion);
        require(sM.id.length > 0, "the function isn't complete rightly. There is no element in 'id[]'");
    }

    //// 음원 구매시 수행해야 할 부분
    // 정산 부분
    // songId로 songMetaData 조회하는 함수
    event logSongMetaData(uint gweiPerBuy, uint[] id, address[] _address, uint[] proportion);
    function getSongMetaData(uint songId) public {
        songMetaData storage sM = payProperty[songId];
        emit logSongMetaData(sM.gweiPerBuy, sM.id, sM._address, sM.proportion);
    }

    // 곡 id, 권리자id로 정산 금액 조회하는 함수
    function getTotalSettlement(uint songId, uint rightHolderId) public view returns(uint){
    songMetaData storage pM = payProperty[songId];
        uint amount = 0;
        for(uint i=0; i<pM.id.length; i++) {
            if (pM.id[i] == rightHolderId) {
                amount = pM.gweiPerBuy * pM.proportion[i];
                break;
            }
        }
        return amount;
    }
    
    // 곡 id당 전체 정산 금액 출력
    function getTotalSettlement(uint songId) public view returns(uint){
    songMetaData storage pM = payProperty[songId];
        uint allAmount = 0;
        for(uint i=0; i<pM.id.length; i++) {
            allAmount += pM.gweiPerBuy * pM.proportion[i];
        }
        return allAmount;
    }

    //send()로 정산하는 함수
    function settleBySend(address payable _to, uint amount)public payable {
        require(msg.sender.balance > amount, "Failed to send Ether. You don't have enough money");
        require(msg.value == amount, "Failed to send Ether. You should send correct wei");
        emit log(msg.value);
        bool sent = payable(_to).send(msg.value);

        require(sent, "Failed to send.");
        emit log(msg.sender.balance);
    }
    
    //금액 결제하는 함수
    function goSettlement(uint songId) public payable{
    songMetaData storage pM = payProperty[songId];
        uint settleAmount = 0;
        for(uint i=0; i<pM.id.length; i++) {
            settleAmount = pM.gweiPerBuy * pM.proportion[i];
            settleBySend(payable(pM._address[i]), settleAmount);
        }
    }

    // 0.7 이상부터 사용
    // 원하는 금액 보내는 call함수
    function call(address payable _to) public payable returns(bool) {
        // 유동적인 가스비를 사용하도록 가스비를 지정하지 않음.
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "failed to send Ether");
        emit log(msg.value);
        return sent;
    }
}