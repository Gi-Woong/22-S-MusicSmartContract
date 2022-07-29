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
        //중복검사를 위한 mapping
        mapping(address => bool) addressIsIn;
        // (음원에 대한 저작권 비율. 최대 100%=>10000)
        uint[] proportion;
        bool created;
    }

    mapping (uint => songMetaData) payProperty;

    //// 음원 업로드시 수행해야 할 부분
    // 곡의 정산에 필요한 정보를 생성하는 함수
    // 복수 저작자 추가 가능
    // songId당 한번만 실행 가능
    function createSongMetaData(uint songId, uint _gweiPerBuy, uint[] memory ids, address[] memory _addresses, uint[] memory proportions) public {
        require(!payProperty[songId].created, "Already existing songMetaData id");
        require(ids.length == _addresses.length &&
                _addresses.length == proportions.length, 
                "Input array's length must be same.");
        // require(payProperty[songId].gweiPerBuy > 0, "You should create songMetaData by using 'createsongMetaData()' first.");
        uint proportionsSum = 0;
        for(uint i=0; i<ids.length; i++) {
            proportionsSum += proportions[i];
        }
        require(proportionsSum == 10000, "Sum of proportions must be 10000");
        payProperty[songId].gweiPerBuy = _gweiPerBuy;
        for(uint i=0; i<ids.length; i++) {
            //중복검사
            require(!payProperty[songId].addressIsIn[_addresses[i]],"Input address is duplicate data");
            payProperty[songId].id.push(ids[i]);
            payProperty[songId]._address.push(_addresses[i]);
            payProperty[songId].addressIsIn[_addresses[i]] = true;
            payProperty[songId].proportion.push(proportions[i]);
        }
        payProperty[songId].created = true;
    }

    //// 음원 구매시 수행해야 할 부분
    // 정산 부분

    //수정자: songId가 있는지 check함.
    //이 절차가 없으면 생성하지 않았는데도 조회가 됨.
    modifier songIdCheck(uint songId) {
        require(payProperty[songId].created, "The songId does not exist.");
        _;
    }

    // songId로 songMetaData 기록하는 함수
    event eventLogSongMetaData(uint gweiPerBuy, uint[] id, address[] _address, uint[] proportion);
    function logSongMetaData(uint songId) public songIdCheck(songId) {
        emit eventLogSongMetaData(payProperty[songId].gweiPerBuy,
                             payProperty[songId].id,
                             payProperty[songId]._address,
                             payProperty[songId].proportion);
    }

    //곡 메타데이터 getter
    function getSongMetaData(uint songId) public view songIdCheck(songId) returns(uint, uint[] memory, address[] memory, uint[] memory){
        return (payProperty[songId].gweiPerBuy,
                payProperty[songId].id,
                payProperty[songId]._address,
                payProperty[songId].proportion);
    }

    //정산을 위한 곡 권리자들 addresses getter
    function getSongHoldersAdresses(uint songId) public view songIdCheck(songId) returns(address[] memory){
        return payProperty[songId]._address;
    }

    // 곡 id당 전체 정산 금액 getter
    function getTotalSettlement(uint songId) public view songIdCheck(songId) returns(uint){
        uint allAmount = 0;
        for(uint i=0; i<payProperty[songId].id.length; i++) {
            allAmount += payProperty[songId].gweiPerBuy * payProperty[songId].proportion[i];
        }
        return allAmount;
    }

    // 곡 id, 권리자id로 정산 금액 조회하는 getter
    function getHolderSettlement(uint songId, uint rightHolderId) public view songIdCheck(songId) returns(uint){
        uint amount = 0;
        bool foundAdress;
        for(uint i=0; i<payProperty[songId].id.length; i++) {
            if (payProperty[songId].id[i] == rightHolderId) {
                foundAdress = true;
                amount = payProperty[songId].gweiPerBuy * payProperty[songId].proportion[i];
                break;
            }
        }
        require(foundAdress, "Wrong address Input");
        return amount;
    }

    event logReceipt(address sender, address reciever, uint amount);
    //call()로 정산하는 함수 
    function settleByCall(address payable _to, uint amount)public payable {
        require(msg.sender.balance > amount, "Failed to send Ether. You don't have enough money");
        require(msg.value == amount, "Failed to send Ether. You should send correct wei");
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
        //정산 기록 log에 저장
        emit logReceipt(msg.sender, _to, amount);
    }
    
    //금액 결제하는 함수
    function goSettlement(uint songId, address payable _to) public payable returns(uint){
        uint settleAmount = 0;
        uint _toIndex = 0;
        bool foundAdress;
        for(uint i=0; i<payProperty[songId].id.length; i++) {
            if(_to == payProperty[songId]._address[i]){
                foundAdress = true;
                break;
            }
            _toIndex += 1;
        }
        require(foundAdress, "Wrong address Input");
        settleAmount = payProperty[songId].gweiPerBuy * payProperty[songId].proportion[_toIndex];
        settleByCall(payable(payProperty[songId]._address[_toIndex]), settleAmount);
        //백엔드에서 곡 결제 완료 체크 용도로 사용하길 기대함.
        // return값 합산이 10000이면 제대로 정산이 이루어진 것.
        return payProperty[songId].proportion[_toIndex];
    }   
} 