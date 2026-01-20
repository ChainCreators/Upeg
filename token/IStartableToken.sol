// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Interface for a token with a start action.
interface IStartableToken {
    /// @notice Sets the liquidity pool address and enables buying.
    function start(address newPool) external;
    /// @notice Checks whether the token is started.
    function isStarted() external view returns (bool);
}