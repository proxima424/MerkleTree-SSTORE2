// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IMerkleTree} from "./IMerkleTree.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IHasher} from "./IHasher.sol";
import {SSTORE2} from "./SSTORE2.sol";

contract MerkleTree2 is IMerkleTree, Initializable {
    using SSTORE2 for bytes;
    using SSTORE2 for address;

    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint32 public constant ROOT_HISTORY_SIZE = 100;

    uint256 public constant ZERO_LEAF = uint256(keccak256("proxima424")) % FIELD_SIZE;

    IHasher public immutable hasher;
    uint256 public immutable numLevels;

    mapping(uint256 => bytes32) public zeroes;
    address public filledSubtree;

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
        bytes32[] memory new_filledSubtree = new bytes32[](20);

        for (uint8 i = 0; i < 20;) {
            zeroes[i] = zero;
            new_filledSubtree[i] = zero;
            zero = hashLeftRight(zero, zero);
            unchecked {
                ++i;
            }
        }

        bytes memory subtree_data = convertIntoBytes(new_filledSubtree);
        // create function to deploy this long 640 bytes into a new address
        filledSubtree = SSTORE2.write(subtree_data);

        // for (uint8 i = 0; i < numLevels;) {
        //     zeroes[i] = zero;
        //     filledSubtrees[i] = zero;
        //     zero = hashLeftRight(zero, zero);

        //     unchecked {
        //         ++i;
        //     }
        // }

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

    ///@notice Fetches bytes data stored at a contract's address into an array[20]
    function getFilledSubtree() internal view returns (bytes32[20] memory arr) {
        bytes memory storedSubtree = SSTORE2.read(filledSubtree); // retreives 32*20 bytes == 640 bytes
        // task :
        assembly {
            let j := 0x20
            for { let i := add(storedSubtree, 0x20) } iszero(eq(i, add(add(storedSubtree, 0x20), mul(0x20, 20)))) {
                i := add(i, 0x20)
            } {
                // mstore(where to store, what to store)
                // what to store = mload(i)
                // where to store = add(arr)
                mstore(add(arr, j), mload(i))
                j := add(j, 0x20)
            }
        }
    }

    ///@notice
    function convertIntoBytes(bytes32[] memory subTreeArr) internal view returns (bytes memory data) {
        assembly {
            mstore(data, 20)
            let j := 0x20
            for { let i := add(subTreeArr, 0x20) } iszero(eq(i, add(add(subTreeArr, 0x20), mul(0x20, 20)))) {
                i := add(i, 0x20)
            } {
                // where to store = add(data,j)
                // what to stor
                mstore(add(data, j), mload(i))
                j := add(j, 0x20)
            }
        }
    }

    function _insert(bytes32 leaf1, bytes32 leaf2) internal returns (uint32 index) {
        uint32 _nextIndex = nextLeafIndex;

        if (_nextIndex >= 2 ** numLevels) revert MerkleTreeFull();

        uint32 currentIndex = _nextIndex / 2;

        bytes32 currentLevelHash = hashLeftRight(leaf1, leaf2);
        bytes32 left;
        bytes32 right;

        // Run the below loop
        // Construct a filledSubtree bytes32 data
        // Create a function to fetch data from i'th index of the bytecode address

        bytes32[20] memory retreived_filledSubtree = getFilledSubtree();
        bytes32[] memory new_filledSubtree = new bytes32[](20);

        for (uint8 i = 1; i < 20;) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeroes[i];
                new_filledSubtree[i] = currentLevelHash;
            } else {
                left = retreived_filledSubtree[i];
                right = currentLevelHash;
            }
            currentLevelHash = hashLeftRight(left, right);
            currentIndex /= 2;
            unchecked {
                ++i;
            }
        }
        // 2 bytes
        // 1 : new bytes data to be deployed BYTE1[640]
        //
        // 2 : fetched bytes

        // create function to convert bytes32[20] memory arr into a long 640 bytes
        bytes memory subtree_data = convertIntoBytes(new_filledSubtree);
        // create function to deploy this long 640 bytes into a new address
        filledSubtree = SSTORE2.write(subtree_data);

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
