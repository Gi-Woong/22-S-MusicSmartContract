// import Web3 from "web3";
import Metamask from "./metamask.js";

let bytecodeSettle;
let abiSettle;
let bytecodeNFT;
let abiNFT;

//index.html의 실행 위치에 따른 상대경로
const importData = async () => {
  bytecodeSettle =
    "./assets/SettlementContractExtra.txt";
  abiSettle = await fetch(
    "./assets/SettlementContractExtra.json"
  ).then((res) => res.json());
  bytecodeNFT =
    "./assets/NFT1155.txt";
  abiNFT = await fetch(
    "./assets/NFT1155.json"
  ).then((res) => res.json());
};

const metamask = new Metamask();

// metamask 초기화 및 컴파일된 컨트랙트 데이터를 불러옴
export const init = async () => {
  await metamask.init();
  await importData();
  // console.log(abiSeller);
  // console.log(abiSettle);
};

// contract deploy에 관한 object
export const deployContract = { 
  // 기본적인 deploy 함수 실행 
  deploy: async (abi, bin, from, args = []) => {
    const data = await fetch(bin).then((res) => res.text());
    const contractInstance = new metamask.web3.eth.Contract(abi);
    return contractInstance
      .deploy({
        data,
        arguments: args,
      })
      .send({
        from,
      })
      .on("error", (err) => {
        console.error(err);
      })
      .on("receipt", (receipt) => {
        console.log(`Contract Receipt: ${receipt.contractAddress}`);
      })
      .then((newContractInstance) => {
        return newContractInstance;
      });
  },
  // deploy settlementContractExtra contract
  settlement: async (addresses, proportions, songCid, price) => { //deployContract.
    const bytes = [
      Web3.utils.padRight(Web3.utils.toHex(songCid.substr(0, 32)), 64),
      Web3.utils.padRight(Web3.utils.toHex(songCid.substr(32)), 64),
    ];
    const args = [addresses, proportions, bytes, price];
    const deployedSettleContract = await deployContract.deploy(
      abiSettle,
      bytecodeSettle,
      metamask.account,
      args
    );
    console.log(
      `Settlement contract deployed: ${deployedSettleContract.options.address}`
    );
    return deployedSettleContract;
  },
  // deploy NFT1155 contract
  nft: async (dir, contract) => { //deployContract.
    const args = [dir, contract];
    console.log("in the nft : " + args);
    const deployedNftContract = await deployContract.deploy(
      abiNFT,
      bytecodeNFT,
      metamask.account,
      args
    );
    console.log(
      `NFT contract deployed: ${deployedNftContract.options.address}`
    );
    return deployedNftContract;
  }
};

//settlementContractExtra contract의 method들과 state variable들에 접근하는 object  
export const settlementContract = {
  instance: null,
  load: (settlementAddr) => {
    settlementContract.instance = new metamask.web3.eth.Contract(
      abiSettle,
      settlementAddr
    );
    settlementContract.instance.setProvider(metamask.web3Provider);
    console.log("Settlement contract loaded:");
    console.log(settlementContract.instance);
  },
  buy: async () => {
    const value = await settlementContract.instance.methods.price().call();
    return settlementContract.instance.methods.buy().send({
      from: metamask.account,
      value,
    });
  },
  settle: async () => {
    return settlementContract.instance.methods.settle().send({
      from: metamask.account,
    });
  },
  destroy: async () => {
    return settlementContract.instance.methods.destroy().send({
      from: metamask.account,
    });
  },

  // get을 붙인 이유는 solidity에서 외부에서 contract를 참조할 경우 
  // state variable에 접근 할 수 있도록 getter가 자동으로 생성되기 
  // ex) copyrightHolders의 getter: getCopyrightHolders()
  variables: {
    getCopyrightHolders: async () => {
      return settlementContract.instance.methods.copyrightHolders().call();
    },
    getCumulativeSales: async () => {
      return settlementContract.instance.methods.cumulativeSales().call();
    },
    getKeccak256Hash: async () => {
      return settlementContract.instance.methods.keccak256Hash().call();
    },
    getOwner: async () => {
      return settlementContract.instance.methods.owner().call(); 
    },
    getPrice: async () => {
      return settlementContract.instance.methods.price().call();
    },
    getSongCid: async () => {
      return Web3.utils.hexToString(
        (await settlementContract.instance.methods.songCid(0).call()) +
          (await settlementContract.instance.methods.songCid(1).call()).substr(
            2
          )
      );
    },
  },
  event: {
    getSettleLog: async (result) => {
      const tx = result.transactionHash;
      const receipt = await metamask.web3.eth.getTransactionReceipt(tx);
      const input = [
        {
          type: "address",
          name: "buyer",
        },
        {
          type: "bytes32[2]",
          name: "songCid",
        },
        {
          type: "uint256",
          name: "amount",
        },
      ];

      console.log(receipt.logs[0]);
      const { data: hexString, topics } = receipt.logs[0];
      return metamask.web3.eth.abi.decodeLog(input, hexString, topics);
    },
    getBuyLog: async (result) => {
      const tx = result.transactionHash;
      const receipt = await metamask.web3.eth.getTransactionReceipt(tx);
      const input = [
        {
          type: "address",
          name: "receiver",
        },
        {
          type: "bytes32[2]",
          name: "songCid",
        },
        {
          type: "uint256",
          name: "amount",
        },
      ];
      const { data: hexString, topics } = receipt.logs[0];
      return metamask.web3.eth.abi.decodeLog(input, hexString, topics);
    },
  },
};

//NFT1155 contract의 method들과 state variable들에 접근하는 object  
export const nftContract = {
  instance: null,
  load: (nftAddr) => {
    console.log("nftAddr : " + nftAddr);
    nftContract.instance = new metamask.web3.eth.Contract(
      abiNFT,
      nftAddr
    );
    console.log("nftContract.instance : " + nftContract.instance);
    nftContract.instance.setProvider(metamask.web3Provider);
    console.log("NFT contract loaded:");
    console.log(nftContract.instance);
  },
  // add NFT1155's methods here.abiNFT
  buy: async () => {
    const value = await nftContract.instance.methods.price().call();
    return nftContract.instance.buy().send({
      from: metamask.account,
    });
  },
  sell: async (value) => {
    return nftContract.instance.methods.sell().send({
      from: metamask.account,
      value
    });
  },
  isCopyrightHolder: () => {
    return nftContract.instance.methods.isCopyrightHolder().send({
      from: metamask.account,
    });
  },
  register: () => {
    return nftContract.instance.methods.register().send({
      from: metamask.account,
    });
  },
  variables: {
    // add NFT1155's state variable getters here.
    getMinter: async () => {
      return nftContract.instance.methods.minter().call();
    },
    getOwner: async () => {
      return nftContract.instance.methods.owner().call();
    },
    getPrice: async () => {
      return nftContract.instance.methods.price().call();
    },
    getProportion: async () => {
      return nftContract.instance.methods.proportion().call();
    },
  },
  //event는 사용하지 않으므로 필요 없음.
}

// 현재 metamask의 account(address)와 balance(잔액)을 logging
export const logAccount = async () => {
  const account = metamask.account;
  const balance = await metamask.web3.eth.getBalance(account);
  console.log(`Account: ${account}\nBalance: ${balance}`);
};
