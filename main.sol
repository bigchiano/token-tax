// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DummyToken is ERC20, Ownable {
    mapping (address => bool) public taxPair;
    uint256 taxPairCount = 0;

    event TaxFrom(address pairAddress, uint256 amount);

    constructor() ERC20("DummyToken", "DM") {
        _mint(_msgSender(), 1000000 * (10**decimals()));

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x48612E6f4cCaB1D3Fd12e4a1f14409ae835a6092
        );
        // Create a uniswap pair for token-eth
        address tokenPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        taxPair[tokenPair] = true;
        taxPairCount = 1;
    }

    function addTaxPairs(address[] memory _taxPair) public onlyOwner() {
        for (uint256 index = 0; index < _taxPair.length; index++) {
            taxPair[_taxPair[index]] = true;
        }
        taxPairCount += _taxPair.length;
    }

    function removeTaxPairs(address[] memory _taxPair) public onlyOwner() {
        for (uint256 index = 0; index < _taxPair.length; index++) {
            taxPair[_taxPair[index]] = false;
        }
        taxPairCount -= _taxPair.length;
    }

    function mint(address account, uint256 value) public onlyOwner() {
        _mint(account, value);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _taxTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _taxTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        return true;
    }

    function _taxTransfer(address from,address to, uint256 amount) private {
        uint256 taxAmount = _takeTax(from, to, amount);
        //remove transaction tax from transfer amount
        _transfer(from, to, amount - taxAmount);
    }

    function _takeTax(address from,address to,uint256 amount) private returns (uint256 taxAmount) {
        // tax transaction if sender is uniswap pair.
        if (taxPair[to] || taxPair[from]) {
            taxAmount = amount / 100;
            _transfer(from, owner(), taxAmount);
            emit TaxFrom(taxPair[to] ? to : from, taxAmount);
        }
    }
}
