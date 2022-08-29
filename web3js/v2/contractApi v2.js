import Web3 from "web3";
// let ca.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
export const ca = {
  web3: null,
  sellerContractInstance: null,
  settlementContractInstance: null,
  // ganache-cli 기준
  defaultNetwork: new Web3(
    Web3.givenProvider ||
      new Web3.providers.HttpProvider("http://localhost:8545")
  ),
  defaultGas: 6721975,
  defaultGasPrice: 20000000000,
  setWeb3: async (network = ca.defaultNetwork) => {
    ca.web3 = new Web3(network);
  },
  getAccounts: async () => {
    return await ca.web3.eth.getAccounts();
  },
  getBalance: async (address) => {
    return await ca.web3.eth.getBalance(address);
  },
  utf8ToHex: (utf8) => {
    // return ca.web3.utils.utf8ToHex(utf8);
    if (utf8.length > 64)
      throw new Error(
        `The parameter ${utf8} is too long! Its length must be shorter than 65.`
      );
    else if (utf8.length > 32) {
      return [
        ca.web3.utils.padRight(ca.web3.utils.utf8ToHex(utf8.substr(0, 32)), 64),
        ca.web3.utils.padRight(ca.web3.utils.utf8ToHex(utf8.substr(32)), 64),
      ];
    }
    return ca.web3.utils.padRight(ca.web3.utils.utf8ToHex(utf8), 64);
  },
  hexToUtf8: (hex) => {
    return ca.web3.utils.hexToUtf8(hex);
  },
  getTransactionReceipt: async function (result) {
    return await ca.web3.eth.getTransactionReceipt(result.transactionHash);
  },
  getAddress: (result) => {
    return result.options.address;
  },
  isSameHash: (addresses, proportions, keccak256Hash) => {
    let hash = ca.web3.utils.keccak256(
      ca.web3.eth.abi.encodeParameters(
        ["address[]", "uint256[]"],
        [addresses, proportions]
      )
    );
    return hash === keccak256Hash;
  },
  deployContract: async (
    abi,
    bin,
    args = [],
    from,
    gas = ca.defaultGas,
    gasPrice = ca.defaultGasPrice
  ) => {
    let contractInstance = new ca.web3.eth.Contract(abi);
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
    // .on("error", function (error) {
    //   console.log(error);
    // })
    // .on("transactionHash", function (transactionHash) {
    //   console.log(transactionHash);
    // });
    return deployedContract;
  },
  logAccounts: async function () {
    let accounts = await ca.web3.eth.getAccounts();
    let balance;
    for (let i = 0; i < accounts.length; i++) {
      balance = await ca.web3.eth.getBalance(accounts[i]);
      console.log(`account ${i}: ${accounts[i]}`);
      console.log(`balance: ${balance}`);
    }
  },
  sellerContract: {
    setContractInstance: (contractInstance) => {
      ca.sellerContractInstance = contractInstance;
    },
    variables: {
      getContractInitatorAddress: async () => {
        return await ca.sellerContractInstance.methods
          .contractInitatorAddress()
          .call();
      },
      getUserId: async () => {
        return await ca.sellerContractInstance.methods.userId().call();
      },
    },
    events: {},
  },
  settlementContract: {
    setContractInstance: (contractInstance) => {
      ca.settlementContractInstance = contractInstance;
    },
    buy: async (from) => {
      // console.log(ca.settlementContractInstance);
      // console.log(await ca.settlementContractInstance.methods.price().call());s
      return await ca.settlementContractInstance.methods.buy().send({
        from: from,
        value: await ca.settlementContractInstance.methods.price().call(),
      });
    },
    settle: async (
      from,
      gas = ca.defaultGas,
      gasPrice = ca.defaultGasPrice
    ) => {
      return await ca.settlementContractInstance.methods.settle().send({
        from: from,
        gas: gas,
        gasPrice: gasPrice,
      });
    },
    destroy: async (from, gas = defaultGas, gasPrice = defaultGasPrice) => {
      return await ca.settlementContractInstance.methods.destroy().send({
        from: from,
        gas: gas,
        gasPrice: gasPrice,
      });
    },
    variables: {
      getCopyrightHolders: async () => {
        return await ca.settlementContractInstance.methods
          .copyrightHolders()
          .call();
      },
      getCumulativeSales: async () => {
        return await ca.settlementContractInstance.methods
          .cumulativeSales()
          .call();
      },
      getKeccak256Hash: async () => {
        return await ca.settlementContractInstance.methods
          .keccak256Hash()
          .call();
      },
      getOwner: async () => {
        return await ca.settlementContractInstance.methods.owner().call();
      },
      getPrice: async () => {
        return await ca.settlementContractInstance.methods.price().call();
      },
      getSongCid: async (index = null) => {
        if (index !== null)
          return ca.settlementContractInstance.methods.songCid(index).call();
        return (
          (await ca.settlementContractInstance.methods.songCid(0).call()) +
          (
            await ca.settlementContractInstance.methods.songCid(1).call()
          ).substr(2)
        );
      },
    },
    events: {
      getBuyLog: async function (result) {
        let receipt = await ca.web3.eth.getTransactionReceipt(
          result.transactionHash
        );
        return ca.web3.eth.abi.decodeLog(
          [
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
          ],
          receipt.logs[0].data,
          receipt.logs[0].topics
        );
      },
      getSettleLog: async function (result) {
        let receipt = await ca.web3.eth.getTransactionReceipt(
          result.transactionHash
        );
        return ca.web3.eth.abi.decodeLog(
          [
            {
              type: "address",
              name: "reciever",
            },
            {
              type: "bytes32[2]",
              name: "songCid",
            },
            {
              type: "uint256",
              name: "amount",
            },
          ],
          receipt.logs[0].data,
          receipt.logs[0].topics
        );
      },
    },
  },
};

// export default ca;
