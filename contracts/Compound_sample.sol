//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/compound.sol";

contract CompoundSample {
    event MyLog(string, uint256);

    function supplyEthToCompound(address payable _cEtherContract)
        public
        payable
        returns (bool)
    {
        // Creating a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);
        cToken.mint.value(msg.value).gas(250000)();
        // Sending ctoken to msg.sender
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
        cToken.approve(_cToken, amount);
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
        cToken.approve(_cToken, amount);
        redeemResult = cToken.redeem(amount);

        emit MyLog("If this is not 0, there was an error", redeemResult);

        msg.sender.transfer(address(this).balance);
        return true;
    }

    function() external payable recieve;

    function borrowEth(
        address payable _cEtherAddress,
        address _comptrollerAddress,
        address _cTokenAddress,
        address _underlyingAddress,
        uint256 _underlyingToSupplyAsCollateral
    ) public returns (uint256) {
        CEth cEth = CEth(_cEtherAddress);
        Comptroller comptroller = Comptroller(_comptrollerAddress);
        CErc20 cToken = CErc20(_cTokenAddress);
        Erc20 underlying = Erc20(_underlyingAddress);

        // Approve transfer of underlying
        underlying.approve(_cTokenAddress, _underlyingToSupplyAsCollateral);

        // Supply underlying as collateral, get cToken in return
        uint256 error = cToken.mint(_underlyingToSupplyAsCollateral);
        require(error == 0, "CErc20.mint Error");
        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = _cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(error[0] == 0, "Comptroller.enterMarkets failed.");
        // Get my account's total liquidity value in Compound
        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(error2 == 0, "Comptroller.getAccountLiquidity failed.");
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account has excess collateral");

        // Borrowing near the max amount will result
        // in your account being liquidated instantly
        emit MyLog("Maximum ETH Borrow (borrow far less!)", liquidity);
        // Get the collateral factor for our collateral
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            _cTokenAddress
        );
        emit MyLog("Collateral Factor", collateralFactorMantissa);

        // Get the amount of ETH added to your borrow each block
        uint256 borrowRateMantissa = cEth.borrowRatePerBlock();
        emit MyLog("Current ETH Borrow Rate", borrowRateMantissa);
        uint256 numWeiToBorrow = 20000000000000000; // 0.02 ETH

        // Borrow, then check the underlying balance for this contract's address
        cEth.borrow(numWeiToBorrow);

        uint256 borrows = cEth.borrowBalanceCurrent(address(this));
        emit MyLog("Current ETH borrow amount", borrows);

        return borrows;
    }

    function borrowErc20(
        address _comptrollerAddress,
        address _cTokenAddress,
        address _underlyingAddress,
        uint256 _underlyingToSupplyAsCollateral
    ) public returns (uint256) {
        Comptroller comptroller = Comptroller(_comptrollerAddress);
        CErc20 cToken = CErc20(_cTokenAddress);
        Erc20 underlying = Erc20(_underlyingAddress);

        // Approve transfer of underlying
        underlying.approve(_cTokenAddress, _underlyingToSupplyAsCollateral);

        // Supply underlying as collateral, get cToken in return
        uint256 error = cToken.mint(_underlyingToSupplyAsCollateral);
        require(error == 0, "CErc20.mint Error");
        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = _cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }
        // Get my account's total liquidity value in Compound
        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(error2 == 0, "Comptroller.getAccountLiquidity failed.");
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account has excess collateral");

        // Borrowing near the max amount will result
        // in your account being liquidated instantly
        emit MyLog("Maximum ETH Borrow (borrow far less!)", liquidity);
        // Get the collateral factor for our collateral
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            _cTokenAddress
        );
        emit MyLog("Collateral Factor", collateralFactorMantissa);

        // Get the amount of ETH added to your borrow each block
        uint256 borrowRateMantissa = cToken.borrowRatePerBlock();
        emit MyLog("Current ETH Borrow Rate", borrowRateMantissa);
        // Borrow a fixed amount of ETH below our maximum borrow amount
        uint256 numWeiToBorrow = 20000000000000000; // 0.02 ETH

        // Borrow, then check the underlying balance for this contract's address
        cToken.borrow(numWeiToBorrow);

        uint256 borrows = cToken.borrowBalanceCurrent(address(this));
        emit MyLog("Current ETH borrow amount", borrows);

        return borrows;
    }

    function EthRepayBorrow(address _cEtherAddress, uint256 amount)
        public
        returns (bool)
    {
        CEth cEth = CEth(_cEtherAddress);
        cEth.repayBorrow.value(amount)();
        return true;
    }
}
