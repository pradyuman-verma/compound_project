//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/compound.sol";

contract CompoundSample {
    using SafeERC20 for IERC20;

    uint256 userTokenBalance = 0;
    function() external payable recieve;

    /* 
    - Supply, withdraw, borrow, repay functions for Eth.
    */

    /*
    @param: cEth contract address, amount to supply
    @dev: mint user Eth to compound protocol and retrive cEth.
    */
    function supplyEthToCompound(address payable _cEtherContract)
        public
        payable
    {
        // Creating a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);
        cToken.mint{value: msg.value}();
        userTokenBalance = cToken.balanceOf(address(this));
    }

    /*
    @param: amount to withdraw, cEth contract address
    @dev: user will withdraw his ether using this func
    */
    function withdrawEth(uint256 _amount, address _cEtherContract) public {
        require(userTokenBalance >= _amount, "Choose lower _amount value");
        // Creating a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // Retrieve your asset based on a cToken amount
        require(cToken.redeem(_amount) == 0, "Redeem failed!!");

        userTokenBalance -= _amount;

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to tranfer ether!!");
    }

    /*
    @param: cEth contract address, cToken Address, amount to borrow, underlying address, amount of underlying
    @dev: user will borrow by putting collateral
    */

    function borrowEth(
        address payable _cEtherAddress,
        address _cTokenAddress,
        uint256 _amount
    ) public payable {
        uint256 amount = _amount;
        CEth cEth = CEth(_cEtherAddress);

        Comptroller comptroller = Comptroller(
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        );
        PriceFeed priceFeed = PriceFeed(
            0x922018674c12a7F0D394ebEEf9B58F186CdE13c1
        );

        uint256 price = priceFeed.getUnderlyingPrice(_cEtherAddress);

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
        require(cEth.borrow(amount) == 0, "Borrow Failed !!");
        (bool sent, ) = msg.sender.call{value: cEth.balanceOf(address(this))}(
            ""
        );
        require(sent, "Failed to transfer Ether");
    }

    function EthRepayBorrow(address _cEtherAddress) public payable {
        CEth cEth = CEth(_cEtherAddress);
        require(cEth.balanceOf(address(this)) >= msg.value, "Invalid amount");
        cEth.repayBorrow{value: msg.value}();
    }

    /**
     * Supply, withdraw, borrow, repay functions for ERC20 token.
     **/

    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) public {
        // Creating a reference to the underlying asset contract
        IERC20 token = IERC20(_erc20Contract);

        // Creating a reference to the corresponding cToken contract
        CErc20 cToken = CErc20(_cErc20Contract);

        // Approve transfer on the ERC20 contract
        token.safeApprove(_cErc20Contract, _numTokensToSupply);
        // sending ether from msg.sender to this contract address
        token.safeTransferFrom(msg.sender, address(this), _numTokensToSupply);
        // Mint cTokens
        require(cToken.mint(_numTokensToSupply) == 0, "Mint error");
        userTokenBalance = cToken.balanceOf(address(this));
    }

    function withdrawErc20Tokens(
        uint256 _amount,
        address _cErc20Contract,
        address _erc20Contract
    ) public {
        require(userTokenBalance >= _amount, "Choose lower _amount value");
        // Creating a reference to the underlying asset contract
        IERC20 token = IERC20(_erc20Contract);
        // Creating a reference to the corresponding cToken contract
        CErc20 cToken = CErc20(_cErc20Contract);

        cToken.approve(_cErc20Contract, _amount);
        require(cToken.redeem(_amount) == 0, "Redeem Failed");

        userTokenBalance -= _amount;

        // transfering erc20 to msg.sender
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function borrowErc20(
        address payable _cTokenAddress,
        address _tokenAddress,
        uint256 _amount,
        uint256 _decimals
    ) public payable {
        uint256 amount = _amount;
        CErc20 cToken = CErc20(_cTokenAddress);
        IERC20 token = IERC20(_tokenAddress);

        Comptroller comptroller = Comptroller(
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        );
        PriceFeed priceFeed = PriceFeed(
            0x922018674c12a7F0D394ebEEf9B58F186CdE13c1
        );

        uint256 price = priceFeed.getUnderlyingPrice(_cTokenAddress);

        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = _tokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        // Get my account's total liquidity value in Compound
        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(error2 == 0, "Comptroller.getAccountLiquidity failed.");
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account has excess collateral");

        // calculating maximum borrow:
        uint256 maxBorrow = (liquidity * (10**_decimals)) / price;
        require(maxBorrow > _amount, "Can't borrow this much!");

        // Borrow, then check the underlying balance for this contract's address
        require(cToken.borrow(amount) == 0, "Borrow Failed !!");
        token.safeTransfer(msg.sender, _amount);
    }

    function Erc20RepayBorrow(
        address _tokenAddress,
        address _cTokenAddress,
        uint256 _amount
    ) external {
        IERC20 token = IERC20(_tokenAddress);
        CErc20 cToken = CErc20(_cTokenAddress);

        token.safeTransferFrom(msg.sender, address(this), _amount);

        token.safeApprove(_cTokenAddress, _amount);

        require(cToken.repayBorrow(_amount) == 0, "repay failed");
    }
}
