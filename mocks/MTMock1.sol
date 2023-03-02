// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {MerkleTree1} from "../src/MerkleTree_Old.sol";

contract MerkleTreeMock1 is Initializable, MerkleTree1 {
    constructor(uint32 numLevels_, address hasher_) MerkleTree1(numLevels_, hasher_) {}

    function insert(bytes32 leaf1, bytes32 leaf2) public returns (uint32 index) {
        return _insert(leaf1, leaf2);
    }

    function initialize() external initializer {
        __MerkleTree_init();
    }
}