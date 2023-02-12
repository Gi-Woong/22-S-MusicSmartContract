//sellerContract는 depracated되었음. 이전 컨트랙트에 대한 테스트가 적용된 js파일이므로 다시 뜯어고쳐야 함.
// (실행 안되는게 당연)

import { ca } from "./contractApi v2.js";
import fs from "fs";

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
  ca.setWeb3();
  let accounts = await ca.getAccounts();
  const [buyer, seller, contractCreator] = accounts;
  console.log(`buyer:\t${buyer}`);
  console.log(`seller:\t${seller}`);

  const sellerContractInstance = await ca.deployContract(
    sellerAbi,
    sellerBytecode,
    [ca.utf8ToHex(1)],
    contractCreator
  );
  ca.sellerContract.setContractInstance(sellerContractInstance);

  const scAddress = sellerContractInstance.options.address;
  const addresses = accounts.slice(1, 5);
  const proportions = [2500, 2500, 2500, 2500];
  let songCid = ca.utf8ToHex("QmberjDV3Y3WUbvjpMS2EEycMP9z2WcWR7iYQ79ZZgfZN5");
  const price = "9000000000000000000";

  const settlementContractInstance = await ca.deployContract(
    settlementAbi,
    settlementBytecode,
    [
      scAddress, //scAddress
      addresses, //addresses
      proportions, //proportions
      songCid, //songCid
      price, //price
    ],
    contractCreator
  );
  ca.settlementContract.setContractInstance(settlementContractInstance);
  let buyResult = await ca.settlementContract.buy(buyer);
  console.log(await ca.settlementContract.events.getBuyLog(buyResult));
  let settleResult = await ca.settlementContract.settle(seller);
  console.log(await ca.settlementContract.events.getSettleLog(settleResult));

  // 최종 결과 출력
  await ca.logAccounts();
  let balance = await ca.getBalance(settlementContractInstance.options.address);
  console.log(`after settlement Balance: ${balance}`);
  let songCidGot = ca.hexToUtf8(
    await ca.settlementContract.variables.getSongCid()
  );
  let keccak256Hash = await ca.settlementContract.variables.getKeccak256Hash();
  console.log(
    `isSameHash: ${ca.isSameHash(addresses, proportions, keccak256Hash)}`
  );
  console.log(`getSongCid:\t\t${songCidGot}`);
  console.log(
    "Original songCid:\tQmberjDV3Y3WUbvjpMS2EEycMP9z2WcWR7iYQ79ZZgfZN5"
  );
}
main();
