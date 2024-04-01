// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RefuToken is ERC20, Ownable {
  //  using SafeMath for uint256;

    IERC20 public refuToken;
    uint256 private _price; //Token price for ETH. IE: 100 tokens for 1 eth.
    bool private _emergencyStop;

    //Estructura del Activo "tokenizado": El apartamento con el costo en refutoken
     struct TokenizedAsset {
        address owner;
        uint256 totalSupply; //In REUTOKEN
        uint256 remainingSupply;
        string name;
    }

    address public _owner = address(this);
    uint256 public nextTokenId = 1;
    uint256 public fractionalDecimal = 3;


    mapping(address => uint256) private _tokenBalances; //balance interno de Refutoken
    mapping(uint256 => TokenizedAsset) public tokenizedAssets; //Apartamentos "tokenizado" con la estructura
    mapping(address => mapping(uint256 => uint256)) public fractionalBalances; //Balance interno por address de refutoken por apartamento

    //Eventos
    event PriceSet(uint256 price);
    event EmergencyStop(bool stopped);
    event EmergencyStopActivated(address indexed by);
    event TransferEvt(address indexed from, address indexed to, uint256 value);
    event PriceChanged(uint256 oldPrice, uint256 newPrice);
    event TokensPurchased(address indexed purchaser, uint256 amount);
    event TokensReturned(address indexed purchaser, uint256 amount);
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event AssetCreated(uint256 indexed tokenId, address indexed owner, uint256 totalSupply);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to);

    //se genera el REFUTOKEN ERC20
    constructor(uint256 initialPrice, address initialOwner) ERC20("RefuToken", "REFU") Ownable(initialOwner) {
        refuToken = RefuToken(address(this));
        _emergencyStop = false;
        _price = initialPrice; // RefuToken dados por por ETH
        _mint(address(this), 1000000 * 10 ** 18);
        _tokenBalances[address(this)] += 1000000;
    }

    //Mint de Tokens.
    function mint(address account, uint256 amount) external onlyOwner {
        require(!_emergencyStop, "Minting is stopped");
        _mint(account, amount);
        _tokenBalances[account] += amount;
    }

    //Función para ajueste de precio de REFUTOKEN.
    function setPrice(uint256 price) external onlyOwner {
        require(price > 0, "Price must be greater than zero");
        emit PriceChanged(_price, price);
        _price = price;
        emit PriceSet(price);
    }

    //Función de paro de emergencia.
    function emergencyStop(bool stopped) external onlyOwner {
        _emergencyStop = stopped;
        emit EmergencyStop(stopped);
        if (stopped) {
            emit EmergencyStopActivated(msg.sender);
        }
    }


    //Función para que el cliente/usuario compre REFUTOKENS
    function CustomerBuyToken(uint numTokens) external payable returns (bool) {
            require(!_emergencyStop, "Sell is stopped");
            uint256 amount = msg.value / _price;
            require(amount > 0, "Insufficient Ether sent");

            require(numTokens <= refuToken.balanceOf(address(this)),"No enough Tokens to sell");
            //Ajusta Balances internos de REFUTOKEN
            _tokenBalances[address(this)] -= numTokens;
            _tokenBalances[msg.sender] += numTokens;
            // Transfiere Tokens al  msg.sender
            (bool sent) = refuToken.transfer(msg.sender, numTokens * 10 ** 18);
            require(sent, "Failed to transfer token to user");

            emit TokensPurchased( msg.sender, numTokens);
    return true;
    }

    //Función para Regresar al cliente/msg.sender REFUTOKENS a su cuenta desde el apartamento donde se prestó
    function ReturnToken(uint TokenId, uint256 numTokens) external returns (bool) {
            require(!_emergencyStop, "Operation is stopped");
            require(numTokens <= fractionalBalances[msg.sender][TokenId]);
            require(numTokens <= refuToken.balanceOf(address(this)),"No enough Tokens to return");
            _tokenBalances[msg.sender] += numTokens;
            _tokenBalances[address(this)] -= numTokens;
            fractionalBalances[msg.sender][TokenId] += numTokens;
            fractionalBalances[address(this)][TokenId] -= numTokens;
            // Transfer token to the msg.sender
            refuToken.transferFrom(address(this), msg.sender, numTokens);

            emit TokensReturned( msg.sender, numTokens);
    return true;
    }



        //Funciòn para crear el apartamento,

        function createAsset(uint256 totalSupply, string memory assetName ) public onlyOwner {
        require(totalSupply > 0, "Total supply must be greater than zero");

        tokenizedAssets[nextTokenId] = TokenizedAsset({
            owner: _owner,
            totalSupply: totalSupply,
            remainingSupply: totalSupply,
            name: assetName
        });
        fractionalBalances[_owner][nextTokenId] += totalSupply;
        nextTokenId++;

        emit AssetCreated(nextTokenId - 1, _owner, totalSupply);
    }


    //Funciòn para que el cliente presete una fracciòn del apartamento con REFUTOKENS
    function CustomerBuyAsset(uint256 tokenId, uint256 amount) external {
        TokenizedAsset storage asset = tokenizedAssets[tokenId];
        //require(asset.owner == msg.sender, "Only the owner can transfer ownership");
        require(amount > 0 && amount <= asset.remainingSupply, "Invalid amount to transfer");

        asset.remainingSupply -= amount;
        //Asigna al balance fraccional la cantidad de token al usuario
        fractionalBalances[msg.sender][tokenId] += amount;
        //Quita al balance fraccional la cantidad de token al contrato
        fractionalBalances[_owner][tokenId] -= amount;
        //Reduce el balance de token del usuario.
        _tokenBalances[msg.sender] -= amount;
        // Trasnfiere el REFUTOKEN desde prestador al contrato
        (bool sent) = refuToken.transfer(address(this), amount * 10 ** 18);
        require(sent, "Failed to transfer token to user");

        emit OwnershipTransferred(tokenId, msg.sender, address(this));
    }



    //Funciones de consulta

    //Balance interno de refutoken
    function balanceOf(address account) public view override returns (uint256) {
        return _tokenBalances[account];
    }

    //Balance de refutoken en cuentas.
    function REFUbalanceOf(address account) public view returns (uint256) {
        return refuToken.balanceOf(account);
    }

    //Consulta Balance de ETH
    function ethbalance(address account) public view returns  (uint256) {
        return account.balance;
    }

    //Consulta Balance fraccional de Asset (apartamento) por cuenta
    function fractionalOwnership(uint256 tokenId, address ownerAddress) public view returns (uint256) {
        return fractionalBalances[ownerAddress][tokenId];
    }

    //Consulta el precio del REFUTOKEN (Tokens por ETH)
    function getPrice() public view returns (uint256) {
        return _price;
    }

    //Consulta el paro de emergencia.
    function getEmergencyStopStatus() public view returns (bool) {
        return _emergencyStop;
    }

}
/*
    library SafeMath {
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
        }

        function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
        }
    }
*/
