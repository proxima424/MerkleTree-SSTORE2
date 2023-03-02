// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IMerkleTree} from "./IMerkleTree.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IHasher} from "./IHasher.sol";

contract MerkleTree1 is IMerkleTree, Initializable {
    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint32 public constant ROOT_HISTORY_SIZE = 100;

    uint256 public constant ZERO_LEAF = uint256(keccak256("proxima424")) % FIELD_SIZE;

    IHasher public immutable hasher;
    uint256 public immutable numLevels;

    mapping(uint256 => bytes32) public zeroes;
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;

    uint32 public currentRootIndex;
    uint32 public nextLeafIndex;

    constructor(uint256 numLevels_, address hasher_) {
        if (numLevels_ == 0 || numLevels_ >= 32) revert OutOfRangeMerkleTreeDepth(numLevels_);

        numLevels = numLevels_;
        hasher = IHasher(hasher_);
    }

    function __MerkleTree_init() internal onlyInitializing {
        // Calculate the zero nodes
        bytes32 zero = bytes32(ZERO_LEAF);
        for (uint8 i = 0; i < numLevels;) {
            zeroes[i] = zero;
            filledSubtrees[i] = zero;
            zero = hashLeftRight(zero, zero);

            unchecked {
                ++i;
            }
        }

        roots[0] = zero;
    }

    function hashLeftRight(bytes32 left, bytes32 right) public view returns (bytes32) {
        if (uint256(left) >= FIELD_SIZE) revert InputOutOfFieldSize(left);
        if (uint256(right) >= FIELD_SIZE) revert InputOutOfFieldSize(right);

        bytes32[2] memory input;
        input[0] = left;
        input[1] = right;

        return hasher.poseidon(input);
    }

    function _insert(bytes32 leaf1, bytes32 leaf2) internal returns (uint32 index) {
        uint32 _nextIndex = nextLeafIndex;

        if (_nextIndex >= 2 ** numLevels) revert MerkleTreeFull();

        uint32 currentIndex = _nextIndex / 2;

        bytes32 currentLevelHash = hashLeftRight(leaf1, leaf2);
        bytes32 left;
        bytes32 right;

        for (uint8 i = 1; i < numLevels;) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeroes[i];
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = hashLeftRight(left, right);
            currentIndex /= 2;

            unchecked {
                ++i;
            }
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelHash;

        nextLeafIndex = _nextIndex + 2;
        return _nextIndex;
    }

    function isKnownRoot(bytes32 root) public view returns (bool) {
        if (root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint256 i = _currentRootIndex;
        do {
            if (root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            --i;
        } while (i != _currentRootIndex);
        return false;
    }

    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }

    uint256[46] __gap;
}
