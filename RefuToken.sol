// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RefuToken is ERC20, Ownable {
    uint256 private _price;
    bool private _emergencyStop;
    mapping(address => uint256) private _tokenBalances;

    event PriceSet(uint256 price);
    event EmergencyStop(bool stopped);
    event EmergencyStopActivated(address indexed by);
    event TransferEvt(address indexed from, address indexed to, uint256 value);
    event PriceChanged(uint256 oldPrice, uint256 newPrice);

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

}
