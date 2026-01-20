// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for providing a random seed.
interface IRandomSeedProvider {
    /// @dev Returns a seed for pseudo-random generation.
    function randomSeed() external view returns (uint256);
}