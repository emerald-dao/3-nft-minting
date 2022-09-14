import ExampleNFT from "../ExampleNFT.cdc"

pub fun main(): [&ExampleNFT.NFT?] {
  let answer: [&ExampleNFT.NFT?] = []
  let availableNFTIds = ExampleNFT.getAvailableNFTIds()
  for id in availableNFTIds {
    answer.append(ExampleNFT.getNFTMetadata(nftId: id))
  }

  return answer
}