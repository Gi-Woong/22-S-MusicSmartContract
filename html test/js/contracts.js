// import Web3 from "web3";
import Metamask from "./metamask.js";

let bytecodeSeller;
let abiSeller;
let bytecodeSettle;
let abiSettle;

//index.html의 실행 위치에 따른 상대경로
const importData = async () => {
  bytecodeSeller = "./assets/contracts_SellerContract_sol_SellerContract.txt";
  abiSeller = await fetch(
    "./assets/contracts_SellerContract_sol_SellerContract.json"
  ).then((res) => res.json());
  bytecodeSettle =
    "./assets/contracts_SettlementContract_sol_SettlementContract.txt";
  // bytecodeSettle = await fetch(
  //   "../assets/contracts_SettlementContract_sol_SettlementContract.txt"
  // ).then((txt) => txt.text());
  abiSettle = await fetch(
    "./assets/contracts_SettlementContract_sol_SettlementContract.json"
  ).then((res) => res.json());
};

const metamask = new Metamask();

export const init = async () => {
  await metamask.init();
  await importData();
  // console.log(abiSeller);
  // console.log(abiSettle);
};

export const deployContract = {
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
  seller: async (userId) => {
    const args = [Web3.utils.toHex(userId.toString())];
    const deployedSellerContract = await deployContract.deploy(
      abiSeller,
      bytecodeSeller,
      metamask.account,
      args
    );
    console.log(
      `Seller contract  deployed: ${deployedSellerContract.options.address}`
    );
    return deployedSellerContract;
  },
  settlement: async (scAddress, addresses, proportions, songCid, price) => {
    const bytes = [
      Web3.utils.padRight(Web3.utils.toHex(songCid.substr(0, 32)), 64),
      Web3.utils.padRight(Web3.utils.toHex(songCid.substr(32)), 64),
    ];
    const args = [scAddress, addresses, proportions, bytes, price];
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
};

export const sellerContract = {
  instance: null,
  load: (sellerAddr) => {
    sellerContract.instance = new metamask.web3.eth.Contract(
      abiSeller,
      sellerAddr
    );
    sellerContract.instance.setProvider(metamask.web3Provider);
    console.log("Seller contract loaded:");
    console.log(sellerContract.instance);
  },
  variables: {
    getContractInitatorAddress: async () => {
      return sellerContract.instance.methods.contractInitatorAddress().call();
    },
    getUserId: async () => {
      return sellerContract.instance.methods.userId().call();
    },
  },
};

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
      const { data: hexString, topcis } = receipt.logs[0];
      return metamask.web3.eth.abi.decodeLog(input, hexString, topcis);
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
      const { data: hexString, topcis } = receipt.logs[0];
      return metamask.web3.eth.abi.decodeLog(input, hexString, topcis);
    },
  },
};

export const logAccount = async () => {
  const account = metamask.account;
  const balance = await metamask.web3.eth.getBalance(account);
  console.log(`Account: ${account}\nBalance: ${balance}`);
};
