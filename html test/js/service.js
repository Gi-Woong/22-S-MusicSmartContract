import * as ca from "./contracts.js";
ca.init().then(() => {
  document
    .getElementById("deployContracts")
    .addEventListener("click", async () => {
      console.log("deployContracts button clicked");
      // deploy SellerContract
      const userId = "1";
      const sellerContractInstance = await ca.deployContract.seller(userId);
      console.log("sellerContract deployed");

      // deploy SettlementContract
      const scAddress = sellerContractInstance.options.address;
      const addresses = [
        "0x0bd2fC01Ddd8472d73F0ff674bA12Edd792FcB8d",
        "0x1Fb5Fd68e9b34F8aF64d3B5e2D80ad9Df96F703B",
      ];
      const proportions = [5000, 5000];
      const SongCid = "QmberjDV3Y3WUbvjpMS2EEycMP9z2WcWR7iYQ79ZZgfZN5";
      const price = "90000000000000000";
      const settlementContractInstance = await ca.deployContract.settlement(
        scAddress,
        addresses,
        proportions,
        SongCid,
        price
      );
      console.log("settlementContract deployed");

      // set settlementContract instace
      ca.settlementContract.load(settlementContractInstance.options.address);
      console.log("deployContract done");
    });

  document.getElementById("buy").addEventListener("click", async () => {
    const result = await ca.settlementContract.buy();
    console.log(`buy() Transaction: ${result.transactionHash}`);
  });

  document.getElementById("settle").addEventListener("click", async () => {
    const result = await ca.settlementContract.settle();
    console.log(`settle() Transaction: ${result.transactionHash}`);
  });
});
