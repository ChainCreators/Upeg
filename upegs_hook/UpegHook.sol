// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "../upegs/IUpeg.sol";
import "../svg_generation/SvgGenerator.sol";
import "../library/IRandomSeedProvider.sol";
import "../token/IStartableToken.sol";

/// @notice Hook behavior:
/// - Calls `start` on the configured token when the first liquidity is added for that token pool.
/// - Updates its `randomSeed` on swaps that buy or sell that token.
contract UpegHook is BaseHook, SvgGenerator, IRandomSeedProvider {
    using BalanceDeltaLibrary for BalanceDelta;

    IUpeg public upegs;
    IStartableToken public token;
    uint256 _randomSeed;
    uint256 _randomCount;

    constructor(
        IPoolManager poolManager_,
        address owner_
    ) BaseHook(poolManager_) SvgGenerator(owner_) {
        _randomSeed = block.timestamp;
    }

    function setUpegsAddress(address upegsAddress) external onlyOwner {
        upegs = IUpeg(upegsAddress);
    }

    function setToken(address tokenAddress) external onlyOwner {
        token = IStartableToken(tokenAddress);
    }

    function isTokenSetted() public view returns (bool) {
        return address(token) != address(0);
    }

    function randomSeed() external view override returns (uint256) {
        return _randomSeed;
    }

    function _randomizeSeed() private {
        _randomSeed = uint256(
            keccak256(
                abi.encodePacked(
                    ++_randomCount,
                    _randomSeed,
                    block.timestamp,
                    block.prevrandao,
                    block.number
                )
            )
        );
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        bool isToken = isTokenSetted() &&
            (Currency.unwrap(key.currency1) == address(token) ||
                Currency.unwrap(key.currency0) == address(token));
        if (isToken && !token.isStarted()) token.start(address(poolManager));
        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        // Update randomSeed only for swaps involving our token.
        bool isToken = isTokenSetted() &&
            (Currency.unwrap(key.currency1) == address(token) ||
                Currency.unwrap(key.currency0) == address(token));
        if (!isToken) return (BaseHook.afterSwap.selector, 0);

        _randomizeSeed();
        return (BaseHook.afterSwap.selector, 0);
    }
}
