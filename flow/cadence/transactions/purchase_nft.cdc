import ExampleNFT from "../ExampleNFT.cdc"
import FlowToken from "../utility/FlowToken.cdc"
import NonFungibleToken from "../utility/NonFungibleToken.cdc"
import MetadataViews from "../utility/MetadataViews.cdc"

transaction(nftId: UInt64, price: UFix64) {
  let Vault: &FlowToken.Vault
  let RecipientCollection: &ExampleNFT.Collection{NonFungibleToken.CollectionPublic}
  
  prepare(signer: AuthAccount) {
    self.Vault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

    /* 
      NOTE: In any normal DApp, you would NOT DO these next 2 lines. You would never want to destroy
      someone's collection if it's already set up. The only reason we do this for the
      tutorial is because there's a chance that, on testnet, someone already has 
      a collection here and it will mess with the tutorial.
    */
    destroy signer.load<@NonFungibleToken.Collection>(from: ExampleNFT.CollectionStoragePath)
    signer.unlink(ExampleNFT.CollectionPublicPath)

    // This is the only part you would have.
    if signer.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath) == nil {
      signer.save(<- ExampleNFT.createEmptyCollection(), to: ExampleNFT.CollectionStoragePath)
      signer.link<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(ExampleNFT.CollectionPublicPath, target: ExampleNFT.CollectionStoragePath)
    }

    self.RecipientCollection = signer.getCapability(ExampleNFT.CollectionPublicPath)
                                .borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>()!
  }

  execute {
    let payment <- self.Vault.withdraw(amount: price) as! @FlowToken.Vault
    ExampleNFT.purchaseNFT(nftId: nftId, recipient: self.RecipientCollection, payment: <- payment)
  }
}