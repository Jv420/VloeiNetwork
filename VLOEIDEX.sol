// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 /$$    /$$ /$$        /$$$$$$  /$$$$$$$$ /$$$$$$       /$$   /$$ /$$$$$$$$ /$$$$$$$$ /$$      /$$  /$$$$$$  /$$$$$$$  /$$   /$$
| $$   | $$| $$       /$$__  $$| $$_____/|_  $$_/      | $$$ | $$| $$_____/|__  $$__/| $$  /$ | $$ /$$__  $$| $$__  $$| $$  /$$/
| $$   | $$| $$      | $$  \ $$| $$        | $$        | $$$$| $$| $$         | $$   | $$ /$$$| $$| $$  \ $$| $$  \ $$| $$ /$$/ 
|  $$ / $$/| $$      | $$  | $$| $$$$$     | $$        | $$ $$ $$| $$$$$      | $$   | $$/$$ $$ $$| $$  | $$| $$$$$$$/| $$$$$/  
 \  $$ $$/ | $$      | $$  | $$| $$__/     | $$        | $$  $$$$| $$__/      | $$   | $$$$_  $$$$| $$  | $$| $$__  $$| $$  $$  
  \  $$$/  | $$      | $$  | $$| $$        | $$        | $$\  $$$| $$         | $$   | $$$/ \  $$$| $$  | $$| $$  \ $$| $$\  $$ 
   \  $/   | $$$$$$$$|  $$$$$$/| $$$$$$$$ /$$$$$$      | $$ \  $$| $$$$$$$$   | $$   | $$/   \  $$|  $$$$$$/| $$  | $$| $$ \  $$
    \_/    |________/ \______/ |________/|______/      |__/  \__/|________/   |__/   |__/     \__/ \______/ |__/  |__/|__/  \__/
*/

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract VLOEIDEX is ERC20Base {
    ERC20Base public token;
    address public contractOwner;

    constructor (address payable _token, address payable _defaultAdmin, string memory _name, string memory _symbol, address payable _owner) ERC20Base(_defaultAdmin, _name, _symbol) {
    token = ERC20Base(_token);
    contractOwner = _owner;
    }

    function getToken() public view returns (uint256) {
    ERC20Base _token = ERC20Base(token);
    return _token.balanceOf(address(this));
    }

    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 _liquidity;
        uint256 balanceInEth = address(this).balance;
        uint256 tokenReserve = getToken();
        ERC20Base _token = ERC20Base(token);

        if (tokenReserve == 0) {
            _token.transferFrom(msg.sender, address(this), _amount);
            _liquidity = balanceInEth;
            _mint(msg.sender, _amount);
        }
        else {
            uint256 reservedEth = balanceInEth - msg.value;
            require(
            _amount >= (msg.value * tokenReserve) / reservedEth,
            "Amount of tokens sent is less than the minimum tokens required"
            );
            _token.transferFrom(msg.sender, address(this), _amount);
        unchecked {
            _liquidity = (totalSupply() * msg.value) / reservedEth;
        }
        _mint(msg.sender, _liquidity);
        }
        return _liquidity;
    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(
            _amount > 0, "Amount should be greater than zero"
        );
        uint256 _reservedEth = address(this).balance;
        uint256 _totalSupply = totalSupply();

        uint256 _ethAmount = (_reservedEth * _amount) / totalSupply();
        uint256 _tokenAmount = (getToken() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_ethAmount);
        ERC20Base(token).transfer(msg.sender ,_tokenAmount);
        return (_ethAmount, _tokenAmount);
    }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    )
    public pure returns (uint256) 
    {
        require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");
        // We are charging a fee of `1%`
        // uint256 inputAmountWithFee = inputAmount * 99;
        uint256 inputAmountWithFee = inputAmount;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        unchecked {
            return numerator / denominator;
        }
    }

    function swapEthTotoken() public payable {
        uint256 _reservedTokens = getToken();
        uint256 _tokensBought = getAmountOfTokens(
            msg.value, 
            address(this).balance, 
            _reservedTokens
        );
        ERC20Base(token).transfer(msg.sender, _tokensBought);
    }

    function swapTokenToEth(uint256 _tokensSold) public {
        uint256 _reservedTokens = getToken();
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            _reservedTokens,
            address(this).balance
        );
        ERC20Base(token).transferFrom(
            msg.sender, 
            address(this), 
            _tokensSold
        );
        payable(msg.sender).transfer(ethBought);
    }

    /**
    * @dev send the entire balance stored in this contract to the owner
    */
    function withdrawContract() public {
        payable(contractOwner).transfer(address(this).balance);
    }
}