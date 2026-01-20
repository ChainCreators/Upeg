// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Structure for pseudo-random generator state.
struct Random {
    uint seed;
    uint nonce;
}

/// @dev Library for pseudo-random number generation.
library RandomLibrary {
    /// @dev Generates the next pseudo-random number.
    /// @param random Generator state struct.
    function next(Random memory random) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(random.seed, ++random.nonce)));
    }
}
