import * as ca from "./contractApi.js";
import Web3 from "web3";
import fs from "fs";
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const settlementBytecode = fs
  .readFileSync(
    "./artifacts/contracts_SettlementContract_sol_SettlementContract.bin"
  )
  .toString();

const sellerBytecode = fs
  .readFileSync("./artifacts/contracts_SellerContract_sol_SellerContract.bin")
  .toString();

const settlementAbi = JSON.parse(
  fs.readFileSync(
    "./artifacts/contracts_SettlementContract_sol_SettlementContract.abi",
    "utf-8"
  )
);
const sellerAbi = JSON.parse(
  fs.readFileSync(
    "./artifacts/contracts_SellerContract_sol_SellerContract.abi",
    "utf-8"
  )
);

async function main() {
  let accounts = await web3.eth.getAccounts();
  const [buyer, seller, contractCreator] = accounts;
  console.log(buyer);
  console.log(seller);

  const sellerContractInstance = await ca.deployContract(
    sellerAbi,
    sellerBytecode,
    [ca.utf8ToHex(1)],
    contractCreator
  );
  ca.sellerContract.setContractInstance(sellerContractInstance);

  const settlementContractInstance = await ca.deployContract(
    settlementAbi,
    settlementBytecode,
    [
      sellerContractInstance.options.address, //scAddress
      accounts.slice(1, 5), //addresses
      [2500, 2500, 2500, 2500], //proportions
      web3.utils.utf8ToHex("songCid"), //songCid
      "9000000000000000000", //price
    ],
    contractCreator
  );
  ca.settlementContract.setContractInstance(settlementContractInstance);
  // let buyResult =
  await ca.settlementContract.buy(buyer);
  // console.log(await ca.settlementContract.event.getBuyLog(buyResult));
  // let settleResult =
  await ca.settlementContract.settle(seller);
  // console.log(await ca.settlementContract.event.getSettleLog(settleResult));
  await ca.logAccounts();
  let balance = await web3.eth.getBalance(
    settlementContractInstance.options.address
  );
  console.log(balance);
  let songCid = await ca.settlementContract.variables.getSongCid();
  console.log(songCid);
  let after = web3.utils.hexToUtf8(songCid);
  console.log(after);
}
main();
