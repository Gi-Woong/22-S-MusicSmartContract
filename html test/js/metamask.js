// import Web3 from "web3";

class Metamask {
  constructor() {
    this.web3 = null;
    this.web3Provider = null;
    this.account = "0x0";
  }

  async init() {
    console.log("Metamask.init()");
    this.web3Provider = await detectEthereumProvider();
    if (!this.web3Provider) {
      console.log("Please install MetaMask!");
    }
    await ethereum
      .request({
        method: "eth_requestAccounts",
      })
      .catch((error) => {
        if (error.code === 4001) {
          // EIP-1193 userRejectedRequest error
          console.log("Please connect to MetaMask.");
        } else {
          console.error(error);
        }
      });
    this.web3 = new Web3(this.web3Provider);
    this.account = this.web3.currentProvider.selectedAddress;
    console.log("Your Account: " + this.account);
  }
}

export default Metamask;
