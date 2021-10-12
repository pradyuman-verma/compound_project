//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/compound.sol";

contract CompoundSample {
    event MyLog(string, uint256);

    mapping(address => uint256) addressToToken;

    uint256 cTokenBalance = 0;
    uint256 cEthBalance = 0;

    function supplyEthToCompound(address payable _cEtherContract)
        public
        payable
        returns (bool)
    {
        // Creating a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);
        cToken.mint{value: msg.value}();
        // Sending ctoken to msg.sender
        addressToToken[msg.sender] =
            cToken.balanceOf(address(this)) -
            cTokenBalance;
        cTokenBalance = cToken.balanceOf(address(this));
        cToken.transfer(msg.sender, cToken.balanceOf(address(this)));
        return true;
    }

    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) public returns (uint256) {
        // Creating a reference to the underlying asset contract
        Erc20 token = Erc20(_erc20Contract);

        // Creating a reference to the corresponding cToken contract
        CErc20 cToken = CErc20(_cErc20Contract);

        // Approve transfer on the ERC20 contract
        token.approve(_cErc20Contract, _numTokensToSupply);
        // sending ether from msg.sender to this contract address
        token.transferFrom(msg.sender, address(this), _numTokensToSupply);
        // Mint cTokens
        uint256 mintResult = cToken.mint(_numTokensToSupply);
        // seding ctoken to msg.sender
        cToken.transfer(msg.sender, cToken.balanceOf(address(this)));
        return mintResult;
    }

    function withdrawErc20Tokens(
        uint256 amount,
        bool redeemType,
        address _cErc20Contract,
        address _erc20Contract
    ) public returns (bool) {
        // Creating a reference to the underlying asset contract
        Erc20 token = Erc20(_erc20Contract);
        // Creating a reference to the corresponding cToken contract
        CErc20 cToken = CErc20(_cErc20Contract);

        uint256 redeemResult;

        // transfering ctoken from user to our contract address.
        cToken.transferFrom(msg.sender, address(this), amount);
        cToken.approve(_cErc20Contract, amount);
        redeemResult = cToken.redeem(amount);

        emit MyLog("If this is not 0, there was an error", redeemResult);
        // transfering erc20 to msg.sender
        token.transfer(msg.sender, token.balanceOf(address(this)));

        return true;
    }

    function withdrawEth(
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public returns (bool) {
        // Creating a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        uint256 redeemResult;

        // transfering ctoken from user to our contract address.
        cToken.transferFrom(msg.sender, address(this), amount);
        cToken.approve(_cEtherContract, amount);
        redeemResult = cToken.redeem(amount);

        emit MyLog("If this is not 0, there was an error", redeemResult);

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        return sent;
    }

    function() external payable recieve;

    function borrowEth(
        address payable _cEtherAddress,
        address _comptrollerAddress,
        address _cTokenAddress,
        uint256 _amount
    ) public payable returns (uint256) {
        CEth cEth = CEth(_cEtherAddress);
        CErc20 cToken = CErc20(_cTokenAddress);

        Comptroller comptroller = Comptroller(_comptrollerAddress);
        PriceFeed priceFeed = PriceFeed(
            0x922018674c12a7F0D394ebEEf9B58F186CdE13c1
        );

        uint256 price = priceFeed.getUnderlyingPrice(_cEtherAddress);

        if (addressToToken[msg.sender] == 0) {
            // If user haven't used supplyEth function then use this.
            // Supply underlying as collateral, get cToken in return
            uint256 error = cToken.mint(msg.value);
            require(error == 0, "CErc20.mint Error");
            addressToToken[msg.sender] =
                cToken.balanceOf(address(this)) -
                cTokenBalance;
            cTokenBalance = cToken.balanceOf(address(this));
        } else {
            // else user have some ctoken in its address, then user have to send those ctoken
            // to our contract address
            // Approve transfer of underlying
            cToken.approve(_cTokenAddress, addressToToken[msg.sender]);
            cToken.transferFrom(msg.sender, address(this), _amount);
            addressToToken[msg.sender] =
                cToken.balanceOf(address(this)) -
                cTokenBalance;
            cTokenBalance = cToken.balanceOf(address(this));
        }

        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = _cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        // Get my account's total liquidity value in Compound
        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(error2 == 0, "Comptroller.getAccountLiquidity failed.");
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account has excess collateral");

        // calculating maximum borrow:
        uint256 maxBorrow = (liquidity * (10**18)) / price;
        require(maxBorrow > _amount, "Can't borrow this much!");

        // Borrow, then check the underlying balance for this contract's address
        cEth.borrow(_amount);

        uint256 borrows = cEth.borrowBalanceCurrent(address(this));

        emit MyLog("Current ETH borrow amount", borrows);

        (bool sent, ) = msg.sender.call{value: borrows}("");
        return borrows;
    }

    function EthRepayBorrow(address _cEtherAddress) public returns (bool) {
        CEth cEth = CEth(_cEtherAddress);
        uint256 amount = addressToToken[msg.sender];
        addressToToken[msg.sender] = 0;
        cTokenBalance = cTokenBalance - amount;
        cEth.repayBorrow{value: amount}();
        (bool sent, ) = msg.sender.call{value: cEth.balanceOf(address(this))}(
            ""
        );
        return sent;
    }
}
