// This is an example implementation of a Flow Non-Fungible Token
// It is not part of the official standard but it assumed to be
// very similar to how many NFTs would implement the core functionality.
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"
import FlowToken from "./utility/FlowToken.cdc"
import FungibleToken from "./utility/FungibleToken.cdc"

pub contract ExampleNFT: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let NFTMinterStoragePath: StoragePath

    access(self) let availableNFTs: @{UInt64: NFT}

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let price: UFix64

        init(
            name: String,
            description: String,
            thumbnail: String,
            price: UFix64
        ) {
            self.id = self.uuid
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.price = price

            ExampleNFT.totalSupply = ExampleNFT.totalSupply + 1
        }
    
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
            }
            return nil
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @ExampleNFT.NFT

            let id: UInt64 = token.uuid

            // add the new token to the dictionary which removes the old one
            self.ownedNFTs[id] <-! token

            emit Deposit(id: id, to: self.owner?.address)
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT = nft as! &ExampleNFT.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource NFTMinter {
        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(
            name: String,
            description: String,
            thumbnail: String,
            price: UFix64
        ) {
            // create a new NFT
            var newNFT <- create NFT(
                name: name,
                description: description,
                thumbnail: thumbnail,
                price: price
            )

            ExampleNFT.availableNFTs[newNFT.uuid] <-! newNFT
        }
    }

    pub fun purchaseNFT(nftId: UInt64, recipient: &Collection{NonFungibleToken.CollectionPublic}, payment: @FlowToken.Vault) {
        pre {
            payment.balance == self.getNFTMetadata(nftId: nftId)!.price: "You did not pass in the correct amount of Flow Token."
        }

        let ownerVault = self.account.getCapability(/public/flowTokenReceiver)
                                .borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!
        ownerVault.deposit(from: <- payment)
        
        let nft <- self.availableNFTs.remove(key: nftId) ?? panic("This NFT is not available for purchase, or it doesn't exist.")
        recipient.deposit(token: <- nft)
    }

    pub fun getNFTMetadata(nftId: UInt64): &NFT? {
        return &self.availableNFTs[nftId] as &NFT?
    }

    pub fun getAvailableNFTIds(): [UInt64] {
        return self.availableNFTs.keys
    }
    
    init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.availableNFTs <- {}

        // Set the named paths
        self.CollectionStoragePath = /storage/EmeraldAcademyNFTMintingCollection
        self.CollectionPublicPath = /public/EmeraldAcademyNFTMintingCollection
        self.NFTMinterStoragePath = /storage/EmeraldAcademyNFTMintingMinter

        self.account.save(<- create NFTMinter(), to: self.NFTMinterStoragePath)

        emit ContractInitialized()
    }
}