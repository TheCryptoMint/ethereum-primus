// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BaseERC721.sol";

contract EPRCollection is BaseERC721, ReentrancyGuard {
  receive() external payable {}

  event Deposit(address from, uint256 amount, uint256 tokenId);
  event Withdraw(address to, uint256 amount, uint256 tokenId);
  event OnMarket(uint256 tokenId, uint256 price);
  event OffMarket(uint256 tokenId);
  event Purchase(address seller, address buyer, uint256 tokenId, uint256 amount);

  uint256 constant NULL = 0;
  uint256 public faceValue;

  struct Coin {
    uint256 tokenId;
    uint256 price;
    uint256 fundedValue;
    bool forSale;
  }

  mapping(uint256 => Coin) public coins;

  uint256[] public tokenIds;

  constructor(
    uint256 _mintLimit,
    uint256 _faceValue,
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    string memory _contractURI
  ) BaseERC721(
    _name,
    _symbol,
    _mintLimit,
    _baseURI,
    _contractURI
  ) payable {
    faceValue = _faceValue;
    tokenIds = new uint256[](_mintLimit);
  }

  function createCoin(uint256 _tokenId) internal pure returns (Coin memory) {
    return Coin({
      forSale: false,
      price: uint256(0),
      fundedValue: uint256(0),
      tokenId: _tokenId
    });
  }

  function mint() onlyMinter public returns (uint256) {
    uint256 _tokenId = BaseERC721._mint();
    Coin memory _coin = createCoin(_tokenId);
    coins[_tokenId] = _coin;

    return _tokenId;
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function fund(uint256 _tokenId) nonReentrant onlyMinter external payable {
    confirmTokenExists(_tokenId);
    Coin storage _coin = coins[_tokenId];
    require(_coin.fundedValue == uint256(0), "funded value must be nil");
    require(msg.value == faceValue, "value must be face value");
    _coin.fundedValue = msg.value;

    emit Deposit(msg.sender, msg.value, _tokenId);
  }

  function defund(uint256 _tokenId) nonReentrant onlyMinter external {
    confirmTokenExists(_tokenId);
    confirmTokenFunded(_tokenId);
    Coin storage _coin = coins[_tokenId];
    payable(address(uint160(msg.sender))).transfer(_coin.fundedValue);
    _coin.fundedValue = uint256(0);
    emit Withdraw(msg.sender, _coin.fundedValue, _coin.tokenId);
  }

  function withdraw(Coin memory _coin) private {
    confirmTokenFunded(_coin.tokenId);
    require(_coin.fundedValue != NULL, 'funded value cannot be nil');
    payable(address(uint160(msg.sender))).transfer(_coin.fundedValue);
    emit Withdraw(msg.sender, _coin.fundedValue, _coin.tokenId);
  }

  function burn(uint256 _tokenId) nonReentrant external {
    confirmTokenExists(_tokenId);
    confirmTokenOwner(_tokenId);
    Coin storage _coin = coins[_tokenId];
    require(_coin.forSale == false, "coin cannot be for sale");
    withdraw(_coin);
    ERC721._burn(_tokenId);
    _coin.fundedValue = uint256(0);
  }

  function allowBuy(uint256 _tokenId, uint256 _price) external {
    confirmTokenExists(_tokenId);
    confirmTokenOwner(_tokenId);
    confirmTokenFunded(_tokenId);
    require(_price >= faceValue, 'price must be greater than face value');
    Coin storage _coin = coins[_tokenId];
    _coin.price = _price;
    _coin.forSale = true;
    emit OnMarket(_tokenId, _price);
  }

  function disallowBuy(uint256 _tokenId) external {
    confirmTokenExists(_tokenId);
    confirmTokenOwner(_tokenId);
    confirmTokenFunded(_tokenId);
    Coin storage _coin = coins[_tokenId];
    _coin.price = uint256(0);
    _coin.forSale = false;
    emit OffMarket(_tokenId);
  }

  function buy(uint256 _tokenId) nonReentrant external payable {
    confirmTokenExists(_tokenId);
    address _seller = ownerOf(_tokenId);
    require(_seller != msg.sender, "buyer cannot be seller");
    Coin storage _coin = coins[_tokenId];
    require(_coin.forSale == true, "coin is not for sale");
    require(_coin.price > 0, "coin must have a price greater than face value");
    require(msg.value == _coin.price, "value does not equal the price");
    BaseERC721._buy(_tokenId);
    safeTransferFrom(_seller, msg.sender, _tokenId);
    payable(_seller).transfer(msg.value);
    _coin.forSale = false;
    _coin.price = uint256(0);
    emit Purchase(_seller, msg.sender, _tokenId, msg.value);
  }

  function getCoin(uint256 _tokenId) external view
  returns (
    bool forSale,
    uint256 price,
    uint256 fundedValue,
    string memory uri,
    address owner
  ) {
    Coin memory _coin = coins[_tokenId];
    forSale = _coin.forSale;
    price = _coin.price;
    fundedValue = _coin.fundedValue;
    if (_exists(_tokenId)) {
      owner = ownerOf(_tokenId);
      uri = tokenURI(_tokenId);
    }
    else {
      owner = address(0);
      uri = '';
    }
  }

  function confirmTokenFunded(uint256 _tokenId) internal view {
    Coin memory _coin = coins[_tokenId];
    require(_coin.fundedValue == faceValue, "token must be funded");
  }

  function confirmTokenUnfunded(uint256 _tokenId) internal view {
    Coin memory _coin = coins[_tokenId];
    require(_coin.fundedValue == uint256(0), "token must be unfunded");
  }
}
