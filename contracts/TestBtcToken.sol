// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../openzeppelin/token/ERC20/ERC20.sol";

contract TestBtcToken is ERC20 {
    address owner;

    constructor()
        //ERC20("Cerby Token", "CERBY")
        ERC20("Wrapped BTC Token", "WBTC")
        //ERC20("USD Coin", "USDC")
    {
        owner = msg.sender;
        _mint(0xDc15Ca882F975c33D8f20AB3669D27195B8D87a6, 1e18 * 1e9);
        _mint(0x539FaA851D86781009EC30dF437D794bCd090c8F, 1e18 * 1e9);
        _mint(msg.sender, 1e18 * 1e9);
    }


    function mintByBridge(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnByBridge(address from, uint256 amount) public {
        _burn(from, amount);
    }

    function mintHumanAddress(address to, uint256 amount) public {
        //require(msg.sender == owner);
        _mint(to, amount);
    }

    function burnHumanAddress(address from, uint256 amount) public {
        //require(msg.sender == owner);
        _burn(from, amount);
    }

    function transferCustom(
        address sender,
        address recipient,
        uint256 amount
    ) external {
        _transfer(sender, recipient, amount);
    }
}
