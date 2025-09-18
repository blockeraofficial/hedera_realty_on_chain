const { Client, PrivateKey, TokenCreateTransaction, TokenType, TokenSupplyType } = require("@hashgraph/sdk");

async function main() {
  const OP_ID  = process.env.TESTNET_OPERATOR_ID;
  const OP_HEX = process.env.TESTNET_OPERATOR_PRIVATE_KEY;

  // Parse as ECDSA hex (with or without 0x)
  const OP_KEY = PrivateKey.fromStringECDSA(OP_HEX.replace(/^0x/, ""));

  const client = Client.forTestnet().setOperator(OP_ID, OP_KEY);

  /* 1 HBAR fixed fee to the treasury (can be any collector) (Set a fixed fee later for secondary market transactions)
   
  const fixedFee = new CustomFixedFee()
  .setHbarAmount(new Hbar(1))                           // 👈 100 HBAR (testnet)
  .setFeeCollectorAccountId(AccountId.fromString(OP_ID)); // where the fee goes
  */

  // 🔹 Helper: convert human tokens → smallest unit
  function toSmallestUnit(amount, decimals = 18) {
    return BigInt(amount) * 10n ** BigInt(decimals);
  }

  // 🔹 Create token with 10,000 initial supply
  const initialSupply = toSmallestUnit(10000);

  const tx = await new TokenCreateTransaction()
    .setTokenName("Token1")
    .setTokenSymbol("T1")
    .setTokenType(TokenType.FungibleCommon)
    .setDecimals(8)
    .setInitialSupply(1_000_000_000_000n)   // 10000 T1 tokens are minted
    .setTreasuryAccountId(OP_ID)            // The minted token receiver
    .setSupplyType(TokenSupplyType.FINITE)  // INFINITE MAX SUPPLY
    // .setKycKey(OP_KEY.publicKey)  // 👈 add KYC key here This is off for the testnet purposes
    // .setCustomFees([fixedFee])          // 👈 attach fee schedule
    .freezeWith(client)
    .sign(OP_KEY); // now this is a PrivateKey object

  const receipt = await (await tx.execute(client)).getReceipt(client);
  console.log("HTS token id:", receipt.tokenId?.toString());

  return receipt
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })


// HTS token id: 0.0.6864309