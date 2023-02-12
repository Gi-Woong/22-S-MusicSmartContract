import * as ca from "./contracts.js";
import * as newca from "./contracts_copyright.js";

ca.init().then(() => {
  document
    .querySelector(".deployContracts")
    .addEventListener("click", async () => {
      await ca.init();
      console.log("deployContracts button clicked");
      // deploy SettlementContract              
      const addresses = [
        "0x1Fb5Fd68e9b34F8aF64d3B5e2D80ad9Df96F703B",
        "0x9ba5f78235AB268e92615a2370a81aBB2E79C9eb",
      ];
      const proportions = [5000, 5000];
      const SongCid = "QmWZipPtKnuVkn1mwNMqEw8apx513me2B3aCByCchsCmHk";
      const price = "90000000000000000";
      const settlementContractInstance = await ca.deployContract.settlement(
        addresses,
        proportions,
        SongCid,
        price
      );
      console.log("settlementContract deployed");
      // set settlementContract instance
      ca.settlementContract.load(settlementContractInstance.options.address);
      console.log("deployContract done");
    });

  document.querySelector(".buy").addEventListener("click", async () => {
    await ca.init();
    const result = await ca.settlementContract.buy();
    console.log(`buy() Transaction: ${result.transactionHash}`);
  });

  document.querySelector(".settle").addEventListener("click", async () => {
    await ca.init();
    const result = await ca.settlementContract.settle();
    console.log(`settle() Transaction: ${result.transactionHash}`);
  });
});

newca.init().then(() => {
  document
    .querySelector(".deployNftContract")
    .addEventListener("click", async () => {
      await newca.init();
      console.log("deploy button clicked");
      const addresses = [
        "0x1Fb5Fd68e9b34F8aF64d3B5e2D80ad9Df96F703B",
        "0x9ba5f78235AB268e92615a2370a81aBB2E79C9eb",
      ];
      const proportions = [5000, 5000];
      const SongCid = "QmWZipPtKnuVkn1mwNMqEw8apx513me2B3aCByCchsCmHk";
      const price = "90000000000000000";
      // deploy SettlementContract
      const settlementContractInstance = await newca.deployContract.settlement(
        addresses,
        proportions,
        SongCid,
        price
      );
      console.log("settlementContract deployed");
      
      // deploy NFT Contract
      const dir = "QmWZipPtKnuVkn1mwNMqEw8apx513me2B3aCByCchsCmHk";
      const contract = newca.settlementContract.load(settlementContractInstance.options.address);
      const nftContractInstance = await newca.deployContract.nft(
        dir,
        contract
      );
      console.log("nftContract deployed");

      newca.nftContract.load(nftContractInstance.options.address);
      const registed = await newca.nftContract.register()
      console.log("deployContract done");
    });

  document.querySelector(".nft_buy").addEventListener("click", async () => {
    await newca.init();
    const result = await newca.nftContract.buy();
    console.log(`NFT buy() Transaction: ${result.transactionHash}`);
  });

  document.querySelector(".nft_sell").addEventListener("click", async () => {
    await newca.init();
    const result = await newca.nftContract.sell();
    console.log(`NFT sell() Transaction: ${result.transactionHash}`);
  });
});