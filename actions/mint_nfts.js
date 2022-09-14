const fcl = require("@onflow/fcl");
const { serverAuthorization } = require("./auth/authorization.js");
require("../flow/config.js");

async function mintNFTs() {
  const names = ["Education", "Building", "Governance"];
  const descriptions = [
    "This is the logo of the Education Guild",
    "This is the logo of the Building Guild",
    "This is the logo of the Governance Guild"
  ];
  const thumbnails = [
    "QmYVKNWdm2961QtHz721tdA8dvBT116eT2DtATsX53Kt28",
    "QmPkJbnJSt3ZkHuGAnHyHCAhWVrneRrK6VHMjgu5oPGnoq",
    "QmcpmzEDmZtP37csyNaYaxzhoMQmmUrQsihE3x2XGKsg1Z"
  ];
  const prices = ["20.0", "10.0", "100.0"];

  try {
    const transactionId = await fcl.mutate({
      cadence: `
      import ExampleNFT from 0xDeployer

      transaction(names: [String], descriptions: [String], thumbnails: [String], prices: [UFix64]) {
        let NFTMinter: &ExampleNFT.NFTMinter
        
        prepare(signer: AuthAccount) {
          self.NFTMinter = signer.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.NFTMinterStoragePath) 
                            ?? panic("This signer is not an allowed minter.")
        }

        execute {
          var i = 0
          while i < names.length {
            self.NFTMinter.mintNFT(name: names[i], description: descriptions[i], thumbnail: thumbnails[i], price: prices[i])
            i = i + 1
          }
        }
      }
      `,
      args: (arg, t) => [
        arg(names, t.Array(t.String)),
        arg(descriptions, t.Array(t.String)),
        arg(thumbnails, t.Array(t.String)),
        arg(prices, t.Array(t.UFix64))
      ],
      proposer: serverAuthorization,
      payer: serverAuthorization,
      authorizations: [serverAuthorization],
      limit: 999
    });

    console.log('Transaction Id', transactionId);
  } catch (e) {
    console.log(e);
  }
}

mintNFTs();