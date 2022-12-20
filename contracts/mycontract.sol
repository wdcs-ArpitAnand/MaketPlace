// SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}

/***** 

NOTE:- 
  (1) This NFT Marketplace Contract Will Only List FUL NFT, So Make Sure That NFT Which You Are Listing Or Auctioning That Is FUL NFT 
  (2) Now This Contract Is Not Well Optimized.
  (3) We Have Created View Function Rather Than Making Varibales Public For Increasing Contracts Security Readability.

*****/

contract FULNFTMarketplace is Ownable, ReentrancyGuard {
    struct Listing {
        address creator;
        uint NFTId;
        uint demandedAmount;
        address soldTo;
    }

    struct Auction {
        address creator;
        uint NFTId;
        uint startTime;
        uint endTime;
        uint starterBid;
        uint curBid;
        address curBidder;
        address soldTo;
    }

    struct ListingData {
        uint listingId;
        Listing data;
    }

    struct AuctionData {
        uint auctionId;
        Listing data;
    }

    event FULNFTContractAddressChange(
        address indexed by,
        address indexed oldAddress,
        address indexed newAddress,
        uint at
    );

    event Listed(
        address indexed by,
        uint indexed NFTId,
        uint indexed listingId,
        uint demandedAmount,
        uint at
    );

    event ListingCancel(
        address indexed by,
        uint indexed listingId,
        uint indexed NFTId,
        uint at
    );

    event SoldViaListing(
        address indexed by,
        address indexed to,
        uint indexed NFTId,
        uint listingId,
        uint soldPrice,
        uint at
    );

    event Auctioned(
        address indexed by,
        uint indexed NFTId,
        uint indexed auctionId,
        uint starterBid,
        uint startTime,
        uint endTime,
        uint at
    );

    event AuctionCancel(
        address indexed by,
        uint indexed auctionId,
        uint indexed NFTId,
        uint at
    );

    event BidPlaced(
        uint indexed NFTId,
        address indexed oldBidder,
        address indexed newBidder,
        uint auctionId,
        uint oldBid,
        uint newBid,
        uint at
    );

    event SoldViaAuction(
        address indexed by,
        address indexed to,
        uint indexed NFTId,
        uint auctionId,
        uint soldPrice,
        uint at
    );

    mapping(uint => Listing) private listings;
    mapping(address => uint[]) private userListings;

    mapping(uint => Auction) private auctions;
    mapping(address => uint[]) private userAuctions;

    uint private totalListings;
    uint private totalAuctions;

    uint private listingTrxFee = 1;
    uint private auctionTrxFee = 1;

    uint maxListingDataFetchLimit = 20;
    uint maxAuctionDataFetchLimit = 20;
    IERC721 private FULNFTContract;

    constructor(address FULNFTContractAddress) {
        FULNFTContract = IERC721(FULNFTContractAddress);
        emit FULNFTContractAddressChange(
            msg.sender,
            address(0),
            FULNFTContractAddress,
            block.timestamp
        );
    }

    modifier isValidListingId(uint listingId) {
        require(
            listingId > 0 && listingId <= totalListings,
            "Invalid Listing Id"
        );
        _;
    }

    /********************| Listing Section |********************/

    function listNFT(uint _NFTId, uint _demandedAmount) public returns (uint) {
        address msgSender = msg.sender;
        require(
            FULNFTContract.getApproved(_NFTId) == address(this),
            "You Has Not Approved Your NFT To This Contract"
        );
        require(
            FULNFTContract.ownerOf(_NFTId) == msgSender,
            "Only Owner Of This NFT Can List This NFT"
        );
        FULNFTContract.transferFrom(msgSender, address(this), _NFTId);
        totalListings++;
        uint listingId = totalListings;
        listings[listingId] = Listing(
            msgSender,
            _NFTId,
            _demandedAmount,
            address(0)
        );
        userListings[msgSender].push(listingId);
        emit Listed(
            msgSender,
            _NFTId,
            listingId,
            _demandedAmount,
            block.timestamp
        );
        return listingId;
    }

    function _removeListingData(uint listingId, address listingCreator)
        private
    {
        delete listings[listingId];
        uint[] memory usersListingData = userListings[listingCreator];
        int totalUsersListings = int(usersListingData.length - 1);
        uint totalListings_Data = usersListingData.length;
        while (totalUsersListings >= 0) {
            uint _totalUsersListings = uint(totalUsersListings);
            if (usersListingData[_totalUsersListings] == listingId) {
                if (_totalUsersListings >= totalListings_Data) return;
                for (
                    uint i = _totalUsersListings;
                    i < totalListings_Data - 1;

                ) {
                    usersListingData[i] = usersListingData[i + 1];
                    unchecked {
                        i++;
                    }
                }
                delete usersListingData[totalListings_Data - 1];
                userListings[listingCreator] = usersListingData;
                userListings[listingCreator].pop();
            }
            unchecked {
                totalUsersListings--;
            }
        }
    }

    function cancelListing(uint listingId) public isValidListingId(listingId) {
        address msgSender = msg.sender;
        Listing memory listingData = listings[listingId];
        require(
            listingData.creator == msgSender,
            "Only NFT Lister Can Access This Method"
        );
        require(
            listingData.soldTo == address(0),
            "Listing Is Over Because NFT Is Sold, Now You Cannot Cancel Listing"
        );
        _removeListingData(listingId, msgSender);
        FULNFTContract.transferFrom(
            address(this),
            msgSender,
            listingData.NFTId
        );
        emit ListingCancel(
            msgSender,
            listingId,
            listingData.NFTId,
            block.timestamp
        );
    }

    function endListing(uint listingId) public isValidListingId(listingId) {
        address msgSender = msg.sender;
        Listing memory listingData = listings[listingId];
        require(
            listingData.creator == msgSender,
            "Only NFT Lister Can Access This Method"
        );
        require(
            listingData.soldTo == address(0),
            "Listing Is Over Because NFT Is Sold, Now You Cannot End Listing"
        );
        listings[listingId].soldTo = msgSender;
        FULNFTContract.transferFrom(
            address(this),
            msgSender,
            listingData.NFTId
        );
    }

    function buyListedNFT(uint listingId)
        public
        payable
        isValidListingId(listingId)
    {
        Listing memory listingData = listings[listingId];
        require(
            listingData.soldTo == address(0),
            "You Cannot Buy This NFT Because It Is Already Sold"
        );
        require(
            msg.value >= listingData.demandedAmount,
            "Send Value More Or Equal To Demanded Value"
        );
        address msgSender = msg.sender;
        listings[listingId].soldTo = msgSender;
        FULNFTContract.transferFrom(
            address(this),
            msgSender,
            listingData.NFTId
        );
        uint amountToTransfer = listingData.demandedAmount -
            ((listingData.demandedAmount * listingTrxFee) / 100);
        payable(listingData.creator).transfer(amountToTransfer);
        //_removeListingData(listingId, listingCreator);
        emit SoldViaListing(
            listingData.creator,
            msgSender,
            listingData.NFTId,
            listingId,
            listingData.demandedAmount,
            block.timestamp
        );
    }

    function setListingTrxFee(uint _listingTrxFee) public onlyOwner {
        require(
            _listingTrxFee < 50,
            "Dear Owner You Cannot Set Transaction Fee Price More Than 49%"
        );
        listingTrxFee = _listingTrxFee;
    }

    function setMaxListingFetchDataLimit(uint newLimit) public onlyOwner {
        maxListingDataFetchLimit = newLimit;
    }

    function setNFTContractAddress(address newNFTContractAddress)
        public
        onlyOwner
    {
        address oldNFTContractAddress = address(FULNFTContract);
        FULNFTContract = IERC721(newNFTContractAddress);
        emit FULNFTContractAddressChange(
            msg.sender,
            oldNFTContractAddress,
            newNFTContractAddress,
            block.timestamp
        );
    }

    /***** View Functions *****/

    function _totalListings() public view returns (uint) {
        return totalListings;
    }

    function _listingTransactionFee() public view returns (uint) {
        return listingTrxFee;
    }

    function _FULNFTContractAddress() public view returns (address) {
        return address(FULNFTContract);
    }

    function _usersListings(address userAddress)
        public
        view
        returns (uint[] memory)
    {
        return userListings[userAddress];
    }

    function _listingData(uint listingId)
        public
        view
        isValidListingId(listingId)
        returns (Listing memory)
    {
        return listings[listingId];
    }

    function _userListingsData(address userAddress)
        public
        view
        returns (Listing[] memory)
    {
        uint[] memory usersListings_data = userListings[userAddress];
        uint totalUsersListings = usersListings_data.length;
        Listing[] memory userListingsData_Data = new Listing[](
            totalUsersListings
        );
        for (uint256 i = 0; i < totalUsersListings; ) {
            userListingsData_Data[i] = listings[usersListings_data[i]];
            unchecked {
                i++;
            }
        }
        return userListingsData_Data;
    }

    function getListingData_Range(uint _start, uint _end)
        public
        view
        isValidListingId(_end)
        returns (Listing[] memory)
    {
        require(
            _start <= _end,
            "Invalid Input, Start Num Should Lesser Or Equal To End Num"
        );
        uint _totalDataSize = (_end - _start) + 1;
        require(
            _totalDataSize <= maxAuctionDataFetchLimit,
            "You Cannot Fetch Data More A Than Limit"
        );
        Listing[] memory listingData = new Listing[](_totalDataSize);
        uint256 j;
        for (uint256 i = _start; i <= _end; ) {
            Listing memory _listingData_Temp = listings[i];
            if (_listingData_Temp.creator != address(0)) {
                listingData[j] = _listingData_Temp;
            }
            unchecked {
                i++;
                j++;
            }
        }
        return listingData;
    }

    /********************| Auction Section |********************/

    modifier isValidAuctionId(uint auctionId) {
        require(
            auctionId > 0 && auctionId <= totalAuctions,
            "Invalid Listing Id"
        );
        _;
    }

    function createAuction(
        uint _NFTId,
        uint _starterBid,
        uint _startTime,
        uint _endTime
    ) public returns (uint) {
        address msgSender = msg.sender;
        require(
            _startTime < _endTime,
            "Start Time Should Lesser Than End Time"
        );
        require(
            _startTime > block.timestamp,
            "Start Time Should Greater Than Current Time"
        );
        require(
            FULNFTContract.getApproved(_NFTId) == address(this),
            "You Has Not Approved Your NFT To This Contract"
        );
        require(
            FULNFTContract.ownerOf(_NFTId) == msgSender,
            "Only Owner Of This NFT Can List This NFT"
        );
        FULNFTContract.transferFrom(msgSender, address(this), _NFTId);
        totalAuctions++;
        uint auctionId = totalAuctions;

        auctions[auctionId] = Auction(
            msgSender,
            _NFTId,
            _startTime,
            _endTime,
            _starterBid,
            0,
            address(0),
            address(0)
        );
        userAuctions[msgSender].push(auctionId);
        emit Auctioned(
            msgSender,
            _NFTId,
            auctionId,
            _starterBid,
            _startTime,
            _endTime,
            block.timestamp
        );
        return totalAuctions;
    }

    function endAuction(uint auctionId) public isValidAuctionId(auctionId) {
        address msgSender = msg.sender;
        Auction memory auctionData = auctions[auctionId];
        require(
            (msgSender == auctionData.creator) ||
                ((msgSender == auctionData.curBidder) &&
                    (block.timestamp >= auctionData.endTime)),
            "This Method Can Be Only Called By Auction Creator Or Curbidder. CurBidder Can Call This Method After End Time"
        );
        require(
            auctionData.soldTo == address(0),
            "You Cannot End This Auction Because It Is Already Ended"
        );

        if (auctionData.curBidder != address(0)) {
            auctions[auctionId].soldTo = auctionData.curBidder;
            FULNFTContract.transferFrom(
                address(this),
                auctionData.curBidder,
                auctionData.NFTId
            );
            uint amountToTransfer = auctionData.curBid -
                ((auctionData.curBid * auctionTrxFee) / 100);
            payable(auctionData.creator).transfer(amountToTransfer);
            emit SoldViaAuction(
                auctionData.creator,
                auctionData.curBidder,
                auctionData.NFTId,
                auctionId,
                auctionData.curBid,
                block.timestamp
            );
        } else {
            auctions[auctionId].soldTo = msgSender;
            FULNFTContract.transferFrom(
                address(this),
                msgSender,
                auctionData.NFTId
            );
        }
    }

    function _removeAuctionData(uint auctionId, address auctionCreator)
        private
    {
        delete auctions[auctionId];
        uint[] memory usersAuctionData = userAuctions[auctionCreator];
        int totalUsersAuctions = int(usersAuctionData.length - 1);
        uint totalAuctions_Data = usersAuctionData.length;
        while (totalUsersAuctions >= 0) {
            uint _totalUsersAuctions = uint(totalUsersAuctions);
            if (usersAuctionData[_totalUsersAuctions] == auctionId) {
                if (_totalUsersAuctions >= totalAuctions_Data) return;
                for (
                    uint i = _totalUsersAuctions;
                    i < totalAuctions_Data - 1;

                ) {
                    usersAuctionData[i] = usersAuctionData[i + 1];
                    unchecked {
                        i++;
                    }
                }
                delete usersAuctionData[totalAuctions_Data - 1];
                userAuctions[auctionCreator] = usersAuctionData;
                userAuctions[auctionCreator].pop();
            }
            unchecked {
                totalUsersAuctions--;
            }
        }
    }

    function cancelAuction(uint auctionId) public isValidAuctionId(auctionId) {
        address msgSender = msg.sender;
        Auction memory auctionData = auctions[auctionId];
        require(
            auctionData.creator == msgSender,
            "Only Auction Creator Can Access This Method"
        );
        require(
            auctionData.soldTo == address(0),
            "Auction Is Ended, Now You Cannot Cancel Auction"
        );
        require(
            auctionData.startTime > block.timestamp,
            "Once Auction Is Started Then After It Cannot Be Canceled"
        );
        _removeAuctionData(auctionId, msgSender);
        FULNFTContract.transferFrom(
            address(this),
            msgSender,
            auctionData.NFTId
        );
        emit AuctionCancel(
            msgSender,
            auctionId,
            auctionData.NFTId,
            block.timestamp
        );
    }

    function placeBid(uint auctionId)
        public
        payable
        nonReentrant
        isValidAuctionId(auctionId)
    {
        Auction memory auctionData = auctions[auctionId];
        uint curTime = block.timestamp;
        require(
            auctionData.soldTo == address(0),
            "Now You Cannot Bid In This Auction Because Auction Is Ended"
        );
        // require(auctionData.startTime <= curTime, "Auction Is Not Started");
        require(
            auctionData.endTime > curTime,
            "You Cannot Bid For This Auction Because Auction Time Is Over"
        );
        address msgSender = msg.sender;
        require(
            auctionData.creator != msgSender,
            "Auction Creator Cannot Bid In This Auction"
        );
        uint newBid = msg.value;
        if (auctionData.curBid == 0) {
            require(
                newBid >= auctionData.starterBid,
                "Bid More Or Equal To Starter Bid"
            );
        } else {
            require(
                newBid > auctionData.curBid,
                "Please Bid More Than Current Bid"
            );
        }
        uint oldBid = auctionData.curBid;
        address oldBidder = auctionData.curBidder;
        auctions[auctionId].curBid = newBid;
        auctions[auctionId].curBidder = msgSender;
        payable(oldBidder).transfer(oldBid);
        emit BidPlaced(
            auctionData.NFTId,
            oldBidder,
            msgSender,
            auctionId,
            oldBid,
            newBid,
            curTime
        );
    }

    function setAuctionTrxFee(uint _auctionTrxFee) public onlyOwner {
        require(
            _auctionTrxFee < 50,
            "Dear Owner You Cannot Set Transaction Fee Price More Than 49%"
        );
        auctionTrxFee = _auctionTrxFee;
    }

    function setMaxAuctionFetchDataLimit(uint newLimit) public onlyOwner {
        maxAuctionDataFetchLimit = newLimit;
    }

    /***** View Functions *****/

    function _totalAuctions() public view returns (uint) {
        return totalAuctions;
    }

    function _auctionTransactionFee() public view returns (uint) {
        return auctionTrxFee;
    }

    function _usersAuctions(address userAddress)
        public
        view
        returns (uint[] memory)
    {
        return userAuctions[userAddress];
    }

    function _auctionData(uint auctionId)
        public
        view
        isValidAuctionId(auctionId)
        returns (Auction memory)
    {
        return auctions[auctionId];
    }

    function _userAuctionData(address userAddress)
        public
        view
        returns (Auction[] memory)
    {
        uint[] memory usersAuctions_data = userAuctions[userAddress];
        uint totalUsersAuctions = usersAuctions_data.length;
        Auction[] memory usersAuctionsData_Data = new Auction[](
            totalUsersAuctions
        );
        for (uint256 i = 0; i < totalUsersAuctions; ) {
            usersAuctionsData_Data[i] = auctions[usersAuctions_data[i]];
            unchecked {
                i++;
            }
        }
        return usersAuctionsData_Data;
    }

    function getAuctionData_Range(uint _start, uint _end)
        public
        view
        isValidAuctionId(_end)
        returns (Auction[] memory)
    {
        require(
            _start <= _end,
            "Invalid Input, Start Num Should Lesser Or Equal To End Num"
        );
        uint _totalDataSize = (_end - _start) + 1;
        require(
            _totalDataSize <= maxAuctionDataFetchLimit,
            "You Cannot Fetch Data More A Than Limit"
        );
        Auction[] memory auctionData = new Auction[](_totalDataSize);
        uint256 j;
        for (uint256 i = _start; i <= _end; ) {
            Auction memory _auctionData_Temp = auctions[i];
            if (_auctionData_Temp.creator != address(0)) {
                auctionData[j] = _auctionData_Temp;
            }
            unchecked {
                i++;
                j++;
            }
        }
        return auctionData;
    }

    function temp()public view returns(uint){
        return block.timestamp;
    }
}

