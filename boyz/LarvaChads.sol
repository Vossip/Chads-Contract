// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LarvaChads is Ownable, PaymentSplitter, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _apiURI = "";
    uint256 public _maxSupply = 5000;
    uint256 public _maxAmountToMint = 10;
    uint256 public _maxAmountToHold = 100;
    bool public _isMintingAllowed = false;
    bool private _initialized = false;
    uint256 public _itemPrice = 0.005 ether;

    uint256[] private _shares = [100];
    address[] private _shareholders = [
        0x1B65a9816EF95229ACC3384E67956A7dFaB2b87c
    ];

     modifier mintingAllowed() {
        require(_isMintingAllowed, "Minting not allowed");
        _;
    }

    modifier enoughFunds(uint256 _amountToMint) {
        require(
            msg.value >= _itemPrice.mul(_amountToMint),
            "Insufficient funds"
        );
        _;
    }

    modifier limitTokensToMint(uint256 _amountToMint) {
        require(_amountToMint <= _maxAmountToMint, "Too many tokens at once");
        _;
    }

    modifier limitTokensToHold(uint256 _amountToMint) {
        if (!_isMintingAllowed) {
            require(
                balanceOf(msg.sender).add(_amountToMint) <= _maxAmountToHold,
                "Tokens limit reached"
            );
        }
        _;
    }

    modifier limitSupply(uint256 _amountToMint) {
        require(
            _maxSupply >= _tokenIds.current().add(_amountToMint),
            "The purchase would exceed max tokens supply"
        );
        _;
    }

    constructor()
        PaymentSplitter(_shareholders, _shares)
        ERC721("Larva Chads", "LChads")
    {}

    function _mintMultiple(uint256 _amountToMint) private {
        for (uint256 i = 0; i < _amountToMint; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function mintMultiple(uint256 _amountToMint)
        public
        payable
        mintingAllowed
        limitSupply(_amountToMint)
        enoughFunds(_amountToMint)
        limitTokensToHold(_amountToMint)
        limitTokensToMint(_amountToMint)
    {
        _mintMultiple(_amountToMint);
    }

    function mintReserved(uint256 _amountToMint)
        public
        onlyOwner
        limitSupply(_amountToMint)
    {
        _mintMultiple(_amountToMint);
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _apiURI = _uri;
    }

    function toggleMintingStatus() public onlyOwner {
        _isMintingAllowed = !_isMintingAllowed;
    }

    function setMaxAmountToMint(uint256 maxAmountToMint) public onlyOwner {
        _maxAmountToMint = maxAmountToMint;
    }

    function setMaxAmountToHold(uint256 maxAmountToHold) public onlyOwner {
        _maxAmountToHold = maxAmountToHold;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        _maxSupply = _supply;
    }

    /**
        @dev Transfer balance money to shareholders based on number of shares
     */

    function withdrawParitial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function releaseAll() public onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }
}