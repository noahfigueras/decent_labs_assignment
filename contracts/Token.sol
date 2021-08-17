// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';
import 'hardhat/console.sol';

/// @title Decent Labs Assignment ERC20 Token
/// @author Noah Figueras
/// @notice This is an ERC20 contract with uniswap v3 pool integration 
/// with pair DLAT/ETH

contract Token is ERC20, LiquidityManagement {
    
    address public owner;
    address public uniswapV3FactoryAddress;
    
    uint24 poolFee;
    
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    mapping(uint256 => Deposit) public deposits;
    
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    event PoolSuccessfullyCreated(address pool);
    event OwnershipChanged(address owner);
    event AddedLiquidity(uint128 liquidity);

    modifier onlyOwner() {
        require(msg.sender == owner, "This is not owner of contract");
        _;
    }

    /// @dev Initializes {owner} sets {totalSupply} and defines {uniswapV3FactoryAddress}
    /// and {nonfungiblePositionManager} addresses to use the contracts
    constructor(uint256 totalSupply, address factoryAddress, address _nonfungiblePositionManager) 
    ERC20("Decent Labs Assignment Token", "DLAT")
    PeripheryImmutableState(factoryAddress, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    {
        owner = msg.sender;
        _mint(owner, totalSupply);
        
        //Contract needed to create the pool
        uniswapV3FactoryAddress = address(factoryAddress);
        //Contract needed to provide liquidity to pool
        nonfungiblePositionManager = INonfungiblePositionManager(address(_nonfungiblePositionManager));
    }

    /// @notice Initialize uniswapV3pool DLAT/ETH calling createPool function
    function createPool(address tokenB, uint24 fee) external onlyOwner {
        address pool = IUniswapV3Factory(uniswapV3FactoryAddress).createPool(address(this), tokenB, fee);
        IUniswapV3Pool(pool).initialize(4295128739); 
        poolFee = fee;

        emit PoolSuccessfullyCreated(pool);
    }

    /// @notice adds Liquidity to the pool without open a position
    /// @dev Inherits Function from LiquidityManagment library
    function seedLiquidity(address _token1, uint256 amount0ToMint, uint256 amount1ToMint) 
        external 
        returns(
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
        {
            
        AddLiquidityParams memory params = 
            AddLiquidityParams({
                token0: address(this),
                token1: _token1,
                fee: poolFee,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 50,
                amount1Min: 10000,
                recipient: address(this)
            }); 

            (liquidity, amount0, amount1, pool) = addLiquidity(params);
            
            emit AddedLiquidity(liquidity);
    }

    /// @notice Calls the mint function defined in periphery   
    /// @return tokenId The id of the newly minted ERC721    
    /// @return liquidity The amount of liquidity for the position    
    /// @return amount0 The amount of token0    
    /// @return amount1 The amount of token1
    function mintPosition(address  _token1, uint256 amount0ToMint, uint256 amount1ToMint) 
        external 
        returns(
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
        {
        
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            address(this), _token1, poolFee, 14614467034852101
        );

        // Approve the position manager
        TransferHelper.safeApprove(address(this), address(nonfungiblePositionManager), amount0ToMint);
        TransferHelper.safeApprove(_token1, address(nonfungiblePositionManager), amount1ToMint);

        INonfungiblePositionManager.MintParams memory params = 
            INonfungiblePositionManager.MintParams({
                token0: address(this),
                token1: _token1,
                fee: poolFee,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            }); 

        // Create Position
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        // set the owner and data for position        
        deposits[tokenId] = Deposit({
            owner: msg.sender, 
            liquidity: liquidity, 
            token0: address(this), 
            token1: _token1
        }); 

        // Remove allowance and refund in both assets.        
        if (amount0 < amount0ToMint) {            
           TransferHelper.safeApprove(address(this), address(nonfungiblePositionManager), 0);
            uint256 refund0 = amount0ToMint - amount0;
            TransferHelper.safeTransfer(address(this), msg.sender, refund0);
        }
                
        if (amount1 < amount1ToMint) {
            TransferHelper.safeApprove(_token1, address(nonfungiblePositionManager), 0);
            uint256 refund1 = amount1ToMint - amount1;
            TransferHelper.safeTransfer(_token1, msg.sender, refund1);
        }
    }

    /// @notice changesOwner of contract
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = address(newOwner);
        emit OwnershipChanged(owner);
    }
} 
