// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
}

contract Soloro is Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    uint256 public transactionFee; 
    uint256 public ownerFeePercentage;
    uint256 public burnPercentage;
    address public ecoFundAddress;
    address public tokenOwner; // Nouveau : adresse du créateur du token

    mapping(address => uint256) private _balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply,
        address _ecoFundAddress,
        uint256 _transactionFee,
        uint256 _ownerFeePercentage,
        uint256 _burnPercentage,
        address _tokenOwner // Nouveau : argument pour définir l'adresse du propriétaire
    ) {
        require(_transactionFee.add(_burnPercentage) <= 100, "Invalid fee percentages");
        require(_ecoFundAddress != address(0), "Invalid ecoFund address");
        require(_tokenOwner != address(0), "Invalid token owner address");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = initialSupply * 10**uint256(_decimals);
        ecoFundAddress = _ecoFundAddress;
        tokenOwner = _tokenOwner; // Initialisation
        transactionFee = _transactionFee;
        ownerFeePercentage = _ownerFeePercentage;
        burnPercentage = _burnPercentage;

        _balances[tokenOwner] = _totalSupply; // Allocation initiale au token owner
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero address");
        require(amount <= _balances[sender], "Insufficient balance");

        uint256 fee = amount.mul(transactionFee).div(100);
        uint256 burnAmount = amount.mul(burnPercentage).div(100);
        uint256 ownerFee = fee.mul(ownerFeePercentage).div(100);
        uint256 ecoFundFee = fee.sub(ownerFee);
        uint256 amountAfterFee = amount.sub(fee).sub(burnAmount);

        // Mise à jour des soldes
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountAfterFee);
        _balances[ecoFundAddress] = _balances[ecoFundAddress].add(ecoFundFee);
        _balances[owner] = _balances[owner].add(ownerFee);

        // Burn des tokens
        _totalSupply = _totalSupply.sub(burnAmount);

        emit Transfer(sender, recipient, amountAfterFee);
        emit Burn(sender, burnAmount);
    }
}
