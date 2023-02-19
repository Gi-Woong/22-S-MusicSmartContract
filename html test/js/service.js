import * as newca from "./contracts_copyright.js";

// newca.init().then(() => {
//   document
//     .querySelector(".deployContracts")
//     .addEventListener("click", async () => {
//       await newca.init();
//       console.log("deployContracts button clicked");
//       // deploy SettlementContract
//       const addresses = [
//         // "0x1Fb5Fd68e9b34F8aF64d3B5e2D80ad9Df96F703B",
//         // "0x9ba5f78235AB268e92615a2370a81aBB2E79C9eb",
//         "0x21bfc39E73254320Bd652A248D35063e186901ab",
//       ];
//       const proportions = ["10000"];
//       const SongCid = "QmWZipPtKnuVkn1mwNMqEw8apx513me2B3aCByCchsCmHk";
//       const price = "90000000000000000";
//       const settlementContractInstance = await newca.deployContract.settlement(
//         addresses,
//         proportions,
//         SongCid,
//         price
//       );
//       console.log("settlementContract deployed");
//       // set settlementContract instance
//       newca.settlementContract.load(settlementContractInstance.options.address);
//       console.log("deployContract done");
//     });

//   document.querySelector(".buy").addEventListener("click", async () => {
//     await newca.init();
//     const result = await newca.settlementContract.buy();
//     console.log(`buy() Transaction: ${result.transactionHash}`);
//   });

//   document.querySelector(".settle").addEventListener("click", async () => {
//     await newca.init();
//     const result = await newca.settlementContract.settle();
//     console.log(`settle() Transaction: ${result.transactionHash}`);
//   });
// });

newca.init().then(() => {
  let settleInputs = document.querySelectorAll(".settlement_deploy");
  settleInputs[0].value = `["${newca.metamask.account}"]`;
  settleInputs[1].value = "[10000]";
  settleInputs[2].value = "QmWZipPtKnuVkn1mwNMqEw8apx513me2B3aCByCchsCmHk";
  settleInputs[3].value = "10000000000000000";
  document
    .querySelector(".deploySettlementContract")
    .addEventListener("click", async () => {
      await newca.init();
      console.log("deploy button clicked");
      // console.log(JSON.parse(settleInputs[0].value));
      const addresses = JSON.parse(settleInputs[0].value);
      const proportions = JSON.parse(settleInputs[1].value);
      const SongCid = settleInputs[2].value;
      const price = settleInputs[3].value;
      // deploy SettlementContract
      const settlementContractInstance = await newca.deployContract.settlement(
        addresses,
        proportions,
        SongCid,
        price
      );
      console.log("settlementContract deployed");
      console.log(
        "settlementContractInstance.options.address" +
          settlementContractInstance.options.address
      );
      let nftInputs = document.querySelectorAll(".nft_deploy");
      nftInputs[0].value = "QmXmTpPtKnuVkn1mwNMqEw8apx513me2B3aCByCchsCmHk";
      nftInputs[1].value = settlementContractInstance.options.address;
      console.log("deployContract done");
    });
  document
    .querySelector(".deployNftContract")
    .addEventListener("click", async () => {
      let nftInputs = document.querySelectorAll(".nft_deploy");
      // deploy NFT Contract
      const dir = nftInputs[0].value;
      // newca.settlementContract.load(
      //   newca.settlementContract.instance.option.address
      // );
      const contract = nftInputs[1].value;
      // const contract = newca.settlementContract.instance.options.address;
      console.log("contract : " + contract);
      const nftContractInstance = await newca.deployContract.nft(dir, contract);
      console.log("nftContract deployed");
      newca.nftContract.load(nftContractInstance.options.address);
      console.log("address : " + nftContractInstance.options.address);
      const registed = await newca.nftContract.register();
    });

  //nft 판매 버튼
  document.querySelector(".nft_sell").addEventListener("click", async () => {
    await newca.init();
    // newca.nftContract.load("0x43a53c666acf207df45838f7ef2b7511fc2f1f8d");
    const price = document.querySelector("#nft_sell").value;
    const result = await newca.nftContract.sell(price);
    console.log(`NFT sell() Transaction: ${result.transactionHash}`);
  });
  //nft 구매 버튼
  document.querySelector(".nft_buy").addEventListener("click", async () => {
    await newca.init();
    const price = document.querySelector("#nft_buy").value;
    const result = await newca.nftContract.buy(price);
    console.log(`NFT buy() Transaction: ${result.transactionHash}`);
  });
});

//전역변수에 바인딩
(() => {
  window.newca = newca;
})();
