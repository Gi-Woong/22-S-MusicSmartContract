import Web3 from "web3";
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

let sellerContractInstance;
let settlementContractInstance;
// ganache-cli 기준
const defaultGas = 6721975;
const defaultGasPrice = 20000000000;

export const deployContract = async (
  abi,
  bin,
  args = [],
  from,
  gas = defaultGas,
  gasPrice = defaultGasPrice
) => {
  let contractInstance = new web3.eth.Contract(abi);
  let deployedContract = await contractInstance
    .deploy({
      data: "0x" + bin,
      arguments: args,
    })
    .send({
      from: from, //ganache에서는 gas, gasPrice를 넣어줘야 제대로 작동함... 왜지?
      gas: gas, //ganache에서 설정된 최대 가스 값을 넘어선 안됨
      gasPrice: gasPrice, // gasPrice도 마찬가지.
    });
  return deployedContract;
};

export const sellerContract = {
  setContractInstance: (contractInstance) => {
    sellerContractInstance = contractInstance;
    return sellerContractInstance;
  },
  variables: {
    getContractInitatorAddress: async () => {
      let result = await sellerContractInstance.methods
        .contractInitatorAddress()
        .call();
      return result;
    },
    getUserId: async () => {
      let result = await sellerContractInstance.methods.userId().call();
      return result;
    },
  },
  event: {},
};

export const settlementContract = {
  setContractInstance: (contractInstance) => {
    settlementContractInstance = contractInstance;
    return settlementContractInstance;
  },
  buy: async (from) => {
    // console.log(settlementContractInstance);
    // console.log(await settlementContractInstance.methods.price().call());
    let result = await settlementContractInstance.methods.buy().send({
      from: from,
      value: await settlementContractInstance.methods.price().call(),
    });
    return result;
  },
  settle: async (from, gas = defaultGas, gasPrice = defaultGasPrice) => {
    let result = await settlementContractInstance.methods.settle().send({
      from: from,
      gas: gas,
      gasPrice: gasPrice,
    });
    return result;
  },
  destroy: async (from, gas = defaultGas, gasPrice = defaultGasPrice) => {
    result = await settlementContractInstance.methods.destroy().send({
      from: from,
      gas: gas,
      gasPrice: gasPrice,
    });
    return result;
  },
  variables: {
    getCopyrightHolders: async () => {
      let result = await settlementContractInstance.methods
        .copyrightHolders()
        .call();
      return result;
    },
    getCumulativeSales: async () => {
      let result = await settlementContractInstance.methods
        .cumulativeSales()
        .call();
      return result;
    },
    getKeccak256Hash: async () => {
      let result = await settlementContractInstance.methods
        .keccak256Hash()
        .call();
      return result;
    },
    getOwner: async () => {
      let result = await settlementContractInstance.methods.owner().call();
      return result;
    },
    getPrice: async () => {
      let result = await settlementContractInstance.methods.price().call();
      return result;
    },
    getSongCid: async () => {
      let result = await settlementContractInstance.methods.songCid().call();
      return result;
    },
  },
  event: {
    getSettleLog: async function (result) {
      let tx = result.transactionHash;
      let receipt = await web3.eth.getTransactionReceipt(tx);
      let input = [
        {
          type: "address",
          name: "reciever",
        },
        {
          type: "bytes32",
          name: "songCid",
        },
        {
          type: "uint256",
          name: "amount",
        },
      ];
      let hexString = receipt.logs[0].data;
      let topics = receipt.logs[0].topics;
      let eventLog = web3.eth.abi.decodeLog(input, hexString, topics);
      return eventLog;
    },
    getBuyLog: async function (result) {
      let tx = result.transactionHash;
      let receipt = await web3.eth.getTransactionReceipt(tx);
      let input = [
        {
          type: "address",
          name: "reciever",
        },
        {
          type: "bytes32",
          name: "songCid",
        },
        {
          type: "uint256",
          name: "amount",
        },
      ];
      let hexString = receipt.logs[0].data;
      let topics = receipt.logs[0].topics;
      let eventLog = web3.eth.abi.decodeLog(input, hexString, topics);
      return eventLog;
    },
  },
};

export const logAccounts = async function () {
  let accounts = await web3.eth.getAccounts();
  for (let i = 0; i < accounts.length; i++) {
    let balance = await web3.eth.getBalance(accounts[i]);
    console.log(`account ${i}: ${accounts[i]}`);
    console.log(`balance: ${balance}`);
  }
};
