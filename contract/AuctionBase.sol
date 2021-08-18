pragma solidity ^0.4.0;

contract AuctionBase {

    
    struct Auction {
        
        address seller;
       
        uint128 startingPrice;
        
        uint128 endingPrice;
        
        uint64 duration;
        
        uint64 startedAt;
    }

   
    ERC721 public nonFungibleContract;  

   
    uint256 public ownerCut; 

    
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    
    function _escrow(address _owner, uint256 _tokenId) internal {
       
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    
    function _transfer(address _receiver, uint256 _tokenId) internal {
       
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        
        Auction storage auction = tokenIdToAuction[_tokenId];

       
        require(_isOnAuction(auction));

       
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        
        address seller = auction.seller;

       
        _removeAuction(_tokenId);

      
        if (price > 0) {
            
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

           
            seller.transfer(sellerProceeds);
        }

        
        uint256 bidExcess = _bidAmount - price;

        
        msg.sender.transfer(bidExcess);

       
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

   
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
       
        if (_secondsPassed >= _duration) {
           
            return _endingPrice;
        } else {
            
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    
    function _computeCut(uint256 _price) internal view returns (uint256) {
        
        return _price * ownerCut / 10000;
    }

}
