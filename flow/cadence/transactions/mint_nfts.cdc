import ExampleNFT from "../ExampleNFT.cdc"

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