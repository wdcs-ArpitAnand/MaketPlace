const { expect } = require("chai");
const { ethers, providers, logger } = require("ethers");
// const {loadFixture, deployContract} = waffle;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");
const { inputToConfig } = require("@ethereum-waffle/compiler");

describe("marketpalce",function(){
    beforeEach(async function () {
        [owner,add1,add2,add3,add4] = await hre.ethers.getSigners();
        Token = await hre.ethers.getContractFactory("MyToken");
        ntoken = await Token.deploy();
        await ntoken.deployed();

        Token = await hre.ethers.getContractFactory("Nft");
        ntoken2 = await Token.deploy();
        
        await ntoken2.deployed();

        [owner2] = await hre.ethers.getSigners();
        Token = await hre.ethers.getContractFactory("FULNFTMarketplace");
        market = await Token.deploy(ntoken.address);
        await market.deployed();
        
        mint = await ntoken.safeMint(add1.address)
        wait = await mint.wait();
        nftId = wait.events[0].args[2];

        // provider = waffle.provider;
    });

    describe("ListNFT",function(){
        it("All condition set",async function(){
            // const mint1 = await ntoken.safeMint(add1.address) 
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2])
            console.log(await ntoken.getApproved(wait.events[0].args[2]));
            console.log(market.address);
            
            expect(await market.connect(add1).listNFT(wait.events[0].args[2],1000))
        
        });

        it("when contract not approved not ",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                expect(await market.connect(add1).listNFT(wait.events[0].args[2],1000));
            }
            catch{
                // console.log("You Has Not Approved Your NFT To This Contract");
            }
            
        });

        it("Owner of NFT only able to list",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2])
                expect(await market.listNFT(wait.events[0].args[2],1000))
            }
            catch{
                // console.log("Only Owner Of This NFT Can List This NFT");
            }
        });

        // it("Lsiting details saved or not",async function(){
        //     try{
        //         const mint = await ntoken.safeMint(add1.address)
        //         const wait = await mint.wait();
        //         await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
        //         const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
        //         const lnftwait = await lnft.wait();
        //         const listingID = lnftwait.events[2].args[2];

        //         console.log(await market.connect(add1)._listingData(listingID));
        //     }
        // });
    });

    describe("endListing",function(){
        it("all things correct",async function(){
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            expect(await market.connect(add1).endListing(listingID));        
        });

        it("If user is not lister then he is not able not end list",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                const listingID = lnftwait.events[2].args[2];
                expect(await market.connect(add2).endListing(listingID));
            }
            catch{
                // console.log("Only NFT Lister Can Access This Methods");
            }    
        });


        it("Owner of marketplace also not able to end list ",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                expect(await market.endListing(lnftwait.events[2].args[2]));
            }
            catch{}
        });

        it("if list is ended then NFT trasfer to owner",async function(){
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            const nftId = wait.events[0].args[2];
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            await market.connect(add1).endListing(listingID);
            expect(await ntoken.ownerOf(nftId)).to.equal(add1.address)
        });
        
        it("if nft is sold you can not endlist that NFT",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                const nftId = wait.events[0].args[2];
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                const listingID = lnftwait.events[2].args[2];
                await market.connect(add2).buyListedNFT(listingID,{value:1000});
                expect(await market.connect(add1).endListing(listingID));
            }
            catch{}
        });
    });

    describe("cancelListing",function(){
        it("all things correct then able to cancel the list",async function(){
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            // const {listingID} = await loadFixture(listfixture);
            expect(await market.connect(add1).cancelListing(listingID));
        });

        it("If user is not lister then he is not able not cancellist",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                const listingID = lnftwait.events[2].args[2];
                expect(await market.connect(add2).cancelListing(listingID));
            }
            catch{}    
        });

        it("Owner of marketplace also not able to cancellist ",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                expect(await market.cancelListing(lnftwait.events[2].args[2]));
            }
            catch{}
        });
        
        it("If user is not lister then he is not able not cancellist",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            expect(await market.connect(add2).cancelListing(lnftwait.events[2].args[2]));
            }
            catch{}
        });

        it("if list is ended then NFT trasfer to owner",async function(){
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            const nftId = wait.events[0].args[2];
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            await market.connect(add1).cancelListing(listingID);
            expect(await ntoken.ownerOf(nftId)).to.equal(add1.address)
        });
        it("if nft is sold you can not cancellist that NFT",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                const nftId = wait.events[0].args[2];
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                const listingID = lnftwait.events[2].args[2];
                await market.connect(add2).buyListedNFT(listingID,{value:1000});
                expect(await market.connect(add1).cancelListing(listingID));
            }
            catch{}   
        });
    });

    describe("buyListedNFT",async function(){
        it("if all conditions are met you are able to buy NFT",async function(){
            mint = await ntoken.safeMint(add1.address)
            wait = await mint.wait();
            nftId = wait.events[0].args[2];
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            expect(await market.connect(add2).buyListedNFT(listingID,{value:1000}));
        });

        it("you can not buy if it already sold",async function(){
            try{
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            const nftId = wait.events[0].args[2];
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            await market.connect(add2).buyListedNFT(listingID,{value:1000})
            expect(await market.connect(add2).buyListedNFT(listingID,{value:1000}));
            }
            catch{}    
        });

        it("if you not paid Demanded value you can not buy",async function(){
            try{
                const mint = await ntoken.safeMint(add1.address)
                const wait = await mint.wait();
                const nftId = wait.events[0].args[2];
                await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
                const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
                const lnftwait = await lnft.wait();
                const listingID = lnftwait.events[2].args[2];
                expect(await market.connect(add2).buyListedNFT(listingID,{value:100}));
            }  
            catch{}  
        });

        it("nft transfer to buyer address",async function(){
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            const nftId = wait.events[0].args[2];
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            await market.connect(add2).buyListedNFT(listingID,{value:1000});
            expect(await ntoken.ownerOf(nftId)).to.equal(add2.address)
        });

        it("amount after cutting transaction fee transfer to owner of NFT",async function(){
            const provider = waffle.provider;
            const mint = await ntoken.safeMint(add1.address)
            const wait = await mint.wait();
            const nftId = wait.events[0].args[2];
            await ntoken.connect(add1).approve(market.address,wait.events[0].args[2]);
            const lnft = await market.connect(add1).listNFT(wait.events[0].args[2],1000);
            const lnftwait = await lnft.wait();
            const listingID = lnftwait.events[2].args[2];
            const ldata = await market._listingData(listingID);
            const txfee = await market._listingTransactionFee();
            const amountTransfer = ldata.demandedAmount - ((ldata.demandedAmount*txfee)/100);
            const preBalance = await provider.getBalance(add1.address)
            await market.connect(add2).buyListedNFT(listingID,{value:1000});
            const aftBalance = await provider.getBalance(add1.address);
            expect((aftBalance.sub(preBalance)).eq(amountTransfer));
        });
    });

    describe("setListingTrxFee",function(){
        it("if all conditions met",async function(){
            expect(await market.setListingTrxFee(20));
        });

        it("if your not a admin you can not set the transaction fee",async function(){
            try{
                expect(await market.connect(add1).setListingTrxFee(20));
            }
            catch{}
        });

        it("admin can not able to set the tx fee more than 49",async function(){
            try{
                expect(await market.setListingTrxFee(50));
            }
            catch{}
        });
    });

    describe("setMaxListingFetchDataLimit",function(){
        it("only admin can able to set the data Fetch Limit",async function(){
            expect(await market.setMaxListingFetchDataLimit(20));
        });

        it("if your not owner your not able to set the dataFetchLimit",async function(){
            try{
                expect(await market.connect(add1).setMaxListingFetchDataLimit(20));
            }
            catch{}
        });
    });

    describe("setNFTContractAddress",function(){
        it("only admin can set the ",async function(){
            // console.log(ntoken2.address,ntoken.address);
            expect(await market.setNFTContractAddress(ntoken2.address))
        });

        it("other than admin no one can set NFTAddress",async function(){
            try{
             expect(await market.connect(add1).setNFTContractAddress(ntoken2.address))
            }
            catch{}    
        });

        it("address is change or not",async function(){
            try{
                await market.setNFTContractAddress(ntoken2.address);
                expect(await market._FULNFTContractAddress()).to.equal(ntoken2.address);
            }
            catch{}    
        });
    });

    describe("createAuction",async function(){
        beforeEach("",async function(){
            await ntoken.connect(add1).approve(market.address,nftId);
        });
        it("all condition correct then he is able to create auction",async function(){
            await ntoken.connect(add1).approve(market.address,nftId);
            let startDate = Date.parse(new Date())+100;
            let endDate = startDate + 300;
            expect(await market.connect(add1).createAuction(nftId,100,startDate,endDate));
        });

        it("if start time greater than end time then it should fail",async function(){
            try{
                await ntoken.connect(add1).approve(market.address,nftId);
                let startDate = Date.parse(new Date())+300;
                let endDate =  Date.parse(new Date()) + 200;
                await expect(await market.connect(add1).createAuction(nftId,100,startDate,endDate)).to.be.revertedWith("Start Time Should Lesser Than End Time");
            }
            catch(error){
                // console.error(error);
            }
        });

        it("if start time should Greater than current Time",async function(){
            try{
                await ntoken.connect(add1).approve(market.address,nftId);
                let startDate = Date.parse(new Date())-100;
                // console.log(startDate);
                let endDate =  Date.parse(new Date());
                expect(await market.connect(add1).createAuction(nftId,100,startDate,endDate));
            }
            catch(error){
                // console.error(error);
            }
        });

        it("if you not approve you not able to list",async function(){
            try{
                let startDate = Date.parse(new Date())+100;
                let endDate = startDate + 300;
                expect(await market.connect(add1).createAuction(nftId,100,startDate,endDate));
            }
            catch(error){
                console.log("Error : You Has Not Approved Your NFT To This Contract");
            }
        });

        it("only owner can list NFT",async function(){
            try{
                await ntoken.connect(add1).approve(market.address,nftId);
                let startDate = Date.parse(new Date())+100;
                let endDate = startDate + 300;
                expect(await market.connect(add2).createAuction(nftId,100,startDate,endDate));
            }
            catch(error){
                // console.log("Error : Only Owner Of This NFT Can List This NFT");
            }
        }); 
    });

    describe("placeBid",async function(){
        it("when all condition matches able to bid",async function(){
            await ntoken.connect(add1).approve(market.address,nftId);
            let startDate = Date.parse(new Date())+100;
            let endDate = startDate + 300;
            let m = await market.connect(add1).createAuction(nftId,100,startDate,endDate);
            let wait = await m.wait();
            let auctionID = wait.events[2].args[2];
            expect (await market.placeBid(auctionID,{value:100}));
        });

        it("if bidder bid more he should replace current bidder and also bid value should change",async function(){
            await ntoken.connect(add1).approve(market.address,nftId);
            let startDate = Date.parse(new Date())+100;
            let endDate = startDate + 300;
            let m = await market.connect(add1).createAuction(nftId,100,startDate,endDate);
            let wait = await m.wait();
            let auctionID = wait.events[2].args[2];
            await market.placeBid(auctionID,{value:100})
            // console.log(await market._auctionData(auctionID));
            await market.connect(add2).placeBid(auctionID,{value:1000});
            const auctionData = await market._auctionData(auctionID);
            expect(auctionData[6]).to.equal(add2.address);
            expect(auctionData[5]).to.equal(1000);
        });   
    });   

    describe("endAuction",async function(){
        it("when all condition matches then able to endAuction",async function(){
            await ntoken.connect(add1).approve(market.address,nftId);
            let startDate = Date.parse(new Date())+100;
            let endDate = startDate + 300;
            let m = await market.connect(add1).createAuction(nftId,100,startDate,endDate);
            let wait = await m.wait();
            let auctionID = wait.events[2].args[2];
            await market.placeBid(auctionID,{value:100});
            // expect(await market.endAuction(auctionID));
            expect(await market.connect(add1).endAuction(auctionID));
        });
    });
});