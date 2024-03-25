// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RefuToken is ERC20, Ownable {
    uint256 private _price;
    bool private _emergencyStop;
    uint256 public nextAssetId = 1;
    mapping(address => uint256) private _tokenBalances;
    
    struct TokenizedAsset {
        address owner;
        uint256 totalSupply;
        uint256 remainingSupply;
        uint256 price;
        string uri;
    }
    mapping(uint256 => TokenizedAsset) public tokenizedAssets;
    mapping(address => mapping(uint256 => uint256)) public fractionalAssetBalances;

    
    event PriceSet(uint256 price);
    event EmergencyStop(bool stopped);
    event EmergencyStopActivated(address indexed by);
    event TransferEvt(address indexed from, address indexed to, uint256 value);
    event PriceChanged(uint256 oldPrice, uint256 newPrice);
    event AssetCreated(uint256 indexed assetId, address indexed owner, uint256 totalSupply, uint256 price, string uri);
    event AssetOwnershipTransferred(uint256 indexed assetId, address indexed from, address indexed to);


    constructor(uint256 initialPrice, address initialOwner) ERC20("RefuToken", "REFU") Ownable(initialOwner) {
        _emergencyStop = false;
        _price = initialPrice;
        //_mint(msg.sender, initialSupply);
        _mint(msg.sender, 1000000 * 10 ** decimals()); 
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(!_emergencyStop, "Minting is stopped");
        _mint(account, amount);
        _tokenBalances[account] += amount;
    }

    function setPrice(uint256 price) external onlyOwner {
        require(price > 0, "Price must be greater than zero");
        emit PriceChanged(_price, price);
        _price = price;
        emit PriceSet(price);
    }

    function emergencyStop(bool stopped) external onlyOwner {
        _emergencyStop = stopped;
        emit EmergencyStop(stopped);
        if (stopped) {
            emit EmergencyStopActivated(msg.sender);
        }
    }

    function transfer(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(!_emergencyStop, "Transfers are stopped");
        _tokenBalances[sender] -= amount;
        _tokenBalances[recipient] += amount;
        _transfer(msg.sender, recipient, amount);
        emit TransferEvt(sender, recipient, amount);
        return true;
    }

  /*  function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);
        _tokenBalances[sender] -= amount;
        _tokenBalances[recipient] += amount;
        emit TransferEvt(sender, recipient, amount);
    }
    */
    function balanceOf(address account) public view override returns (uint256) {
        return _tokenBalances[account];
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getEmergencyStopStatus() public view returns (bool) {
        return _emergencyStop;
    }


    //Only Admin 
    function createAsset(uint256 totalSupply, uint256 price, string memory uri) external onlyOwner {
        require(totalSupply > 0, "Total supply must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        tokenizedAssets[nextAssetId] = TokenizedAsset({
            owner: owner,
            totalSupply: totalSupply,
            remainingSupply: totalSupply,
            price: price,
            uri: uri
        });

        nextAssetId++;

        emit AssetCreated(nextAssetId - 1, owner, totalSupply, price, uri);
    }

    function transferAssetOwnership(uint256 assetId, address to, uint256 amount) external {
        TokenizedAsset storage asset = tokenizedAssets[assetId];
        require(asset.owner == msg.sender, "Only the owner can transfer ownership");
        require(amount > 0 && amount <= asset.remainingSupply, "Invalid amount to transfer");

        asset.remainingSupply -= amount;
        fractionalAssetBalances[to][assetId] += amount;

        emit AssetOwnershipTransferred(assetId, msg.sender, to);
    }

    function fractionalOwnership(uint256 tokenId, address ownerAddress) external view returns (uint256) {
        return fractionalAssetBalances[ownerAddress][tokenId];
    }

    function tokenURI(uint256 assetId) public view returns (string memory) {
        return tokenizedAssets[assetId].uri;
    }

}