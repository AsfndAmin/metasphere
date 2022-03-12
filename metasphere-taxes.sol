//SPDX-License-Identifier: un-licensed
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPayment.sol";
// import "./Helpers/ERC721TransferHelper.sol";
//import "./ERC20TransferHelper.sol";

contract metasphereMarket is ERC721Holder, Ownable {
    event TradeStatusChangeEvent(uint256 indexed id, bytes32 status);
    event PriceChangeEvent(uint256 oldPrice, uint256 newPrice);

    IPayment private payment;
    address contractAddress;
    // ERC721TransferHelper private ERC721transferHelper;
   // ERC20TransferHelper private ERC20transferHelper;
    uint256 constant _divider = 1000; // 100 %
    uint256 private tradeCounter = 1;
    address companyWallet = 0x9840b1aA16829684Fc08e6678C2F5CEE82c2e6A3;
    address referralWallet = 0x9840b1aA16829684Fc08e6678C2F5CEE82c2e6A3;
    address marketingWallet = 0x9840b1aA16829684Fc08e6678C2F5CEE82c2e6A3;
    uint256 taxPercentage = 450;
    // (companyPercentage +
    // referralPercentage +
    // marketingPercentage
    // );
    uint256 companyPercentage = 225; // 2.25
    uint256 referralPercentage = 150; // 1.5
    uint256 marketingPercentage = 75; // 0.75
    uint256 taxBaseValue = 10000; // 100%
   

    struct Trade {
        address poster;
        address nft;
        uint256 id;
        uint256 price;
        IPayment.PaymentToken paymentToken;
        bytes32 status; // e.g Open, Executed, Cancelled
    }
    mapping(uint256 => Trade) private trades;

    constructor(
        // ERC721TransferHelper ERC721transferHelper_,
      //  ERC20TransferHelper ERC20transferHelper_,
        address paymentToken_
    ) {
        // ERC721transferHelper = ERC721transferHelper_;
      //  ERC20transferHelper = ERC20transferHelper_;
        payment = IPayment(paymentToken_);
        contractAddress = paymentToken_;
    }

    // Get individual trade
    function getTrade(uint256 trade) public view returns (Trade memory) {
        return trades[trade];
    }

    /* 
    List item in the market place for sale
    item unique id and amount of tokens to be put on sale price of item
    and an additional data parameter if you dont wan to pass data set it to empty string 
    if your sending the transaction through Frontend 
    else if you are send the transaction using etherscan or using nodejs set it to 0x00 
    */

    function openTrade(
        address nft,
        uint256 id,
        uint256 price,
        IPayment.PaymentToken paymentTokens
    ) external {
        _isNotZeroAddr(nft);

        IERC721(nft).transferFrom(
            msg.sender,
            address(this),
            id
        );
        trades[tradeCounter] = Trade({
            poster: payable(msg.sender),
            nft: nft,
            id: id,
            paymentToken: paymentTokens,
            price: price,
            status: "Open"
        });
        emit TradeStatusChangeEvent(tradeCounter, "Open");
        tradeCounter++;
    }

    /*
    Buyer execute trade and pass the trade number
    and an additional data parameter if you dont wan to pass data set it to empty string 
    if your sending the transaction through Frontend 
    else if you are send the transaction using etherscan or using nodejs set it to 0x00 
    */

    // 2.25% total from each sale
    // 1.5% to Nethty token
    // 0.25% to the company
    // 0.5% to the referrer
    // 0.75% to the company if no referral on the sale

    function executeTrade(uint256 tradeId) public {
        Trade memory trade = trades[tradeId];
        require(trade.status == "Open", "Error: Trade is not Open");
        _isNotZeroAddr(trade.poster);
        require(msg.sender != trade.poster, "Error: cannot buy own nft");
        uint256 taxAmount = (trade.price * taxPercentage)/taxBaseValue;
        uint256 posterShare = trade.price - taxAmount;
         uint256 companyShare = (trade.price*companyPercentage)/taxBaseValue;
         uint256 referralShare = (trade.price*referralPercentage)/taxBaseValue;
         uint256 marketingShare = (trade.price*marketingPercentage)/taxBaseValue;


     //   uint8 paymentTokenIx = uint8(trade.paymentToken);
     //   address paymentToken = payment.getPaymentToken(paymentTokenIx);
       IERC20(contractAddress).transferFrom(
       //     paymentToken,
            msg.sender,
            payable(address(this)),
            posterShare
        );

          IERC20(contractAddress).transferFrom(
       //     paymentToken,
            msg.sender,
            payable(address(this)),
            companyShare
        );

         IERC20(contractAddress).transferFrom(
       //     paymentToken,
            msg.sender,
            payable(address(this)),
            referralShare
        );

        IERC20(contractAddress).transferFrom(
       //     paymentToken,
            msg.sender,
            payable(address(this)),
            marketingShare
        );

        IERC721(trade.nft).transferFrom(
            address(this),
            payable(msg.sender),
            trade.id
        );
        trades[tradeId].status = "Executed";
        trades[tradeId].poster = payable(msg.sender);
        emit TradeStatusChangeEvent(tradeId, "Executed");
    }

    /*
    Seller can cancle trade by passing the trade number
    and an additional data parameter if you dont wan to pass data set it to empty string 
    if your sending the transaction through Frontend 
    else if you are send the transaction using etherscan or using nodejs set it to 0x00 
    */

    function cancelTrade(uint256 tradeId) public { 
        Trade memory trade = trades[tradeId];
        require(
            msg.sender == trade.poster,
            "Error: Trade can be cancelled only by poster"
        );
        require(trade.status == "Open", "Error: Trade is not Open");
        IERC721(trade.nft).transferFrom(address(this), payable(trade.poster), trade.id);
        trades[tradeId].status = "Cancelled";
        emit TradeStatusChangeEvent(tradeId, "Cancelled");
    }

    // Get all items which are on sale in the market place
    function getAllOnSale() public view virtual returns (Trade[] memory) {
        uint256 counter = 0;
        uint256 itemCounter = 0;
        for (uint256 i = 0; i < tradeCounter; i++) {
            if (trades[i].status == "Open") {
                counter++;
            }
        }

        Trade[] memory tokensOnSale = new Trade[](counter);
        if (counter != 0) {
            for (uint256 i = 0; i < tradeCounter; i++) {
                if (trades[i].status == "Open") {
                    tokensOnSale[itemCounter] = trades[i];
                    itemCounter++;
                }
            }
        }

        return tokensOnSale;
    }

    /**
     * verify whether caller is zero aaddress or not
     */
    function _isNotZeroAddr(address addr) private pure {
        require(addr != address(0), "vRent::zero address");
    }

    // get all items owned by a perticular address
    function getAllByOwner(address owner) public view returns (Trade[] memory) {
        uint256 counter = 0;
        uint256 itemCounter = 0;
        for (uint256 i = 0; i < tradeCounter; i++) {
            if (trades[i].poster == owner) {
                counter++;
            }
        }

        Trade[] memory tokensByOwner = new Trade[](counter);
        if (counter != 0) {
            for (uint256 i = 0; i < tradeCounter; i++) {
                if (trades[i].poster == owner) {
                    tokensByOwner[itemCounter] = trades[i];
                    itemCounter++;
                }
            }
        }

        return tokensByOwner;
    }

    /*
    Seller can lowner the price of item by specifing trade number and new price
    if he wants to increase the price of item, he can unlist the item and then specify a higher price
    */
    function lowerTokenPrice(uint256 tradeId, uint256 newPrice) public {
        require(
            msg.sender == trades[tradeId].poster,
            "Error: Price can only be set by poster"
        );

        require(trades[tradeId].status == "Open", "Error: Trade is not Open");

        uint256 oldPrice = trades[tradeId].price;
        require(
            newPrice < oldPrice,
            "Error: please specify a price value less than the old price if you want to increase the price, cancel the trade and list again  with a higher price"
        );
        trades[tradeId].price = newPrice;
        emit PriceChangeEvent(oldPrice, newPrice);
    }

    function getTradeCount() public view returns (uint256) {
        return tradeCounter;
    }

    function changeCompanyPercentage(uint256 _addValue)
    external
    {
        require(_addValue <= 1000, "should be less than 1000");
        companyPercentage = _addValue;
    }

     function changeReferralPercentage(uint256 _addValue)
    external
    {
        require(_addValue <= 1000, "should be less than 1000");
        referralPercentage = _addValue;
    }

     function changeMarketingPercentage(uint256 _addValue)
    external
    {
        require(_addValue <= 10000, "should be less than 10000");
        marketingPercentage = _addValue;
    }

    function viewCompanyPercentage()
    external
    view
    returns(uint256)
    {
        return companyPercentage;
    }

    
    function viewReferralPercentage()
    external
    view
    returns(uint256)
    {
        return referralPercentage;
    }

    
    function viewMarketingPercentage()
    external
    view
    returns(uint256)
    {
        return marketingPercentage;
    }



}
