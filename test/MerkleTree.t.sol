// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/Test.sol";
import {MerkleTreeMock1} from "../mocks/MTMock1.sol";
import {MerkleTreeMock2} from "../mocks/MTMock2.sol";

contract MerkleTest is Test {
    uint256 gFork;
    MerkleTreeMock1 mock1;
    MerkleTreeMock2 mock2;

    function setUp() public {
        gFork = vm.createFork("GOERLI RPC", 8530221);
        vm.selectFork(gFork);
        address hasher = 0x8D08ac9a511581C7e5BDf8CEd27b7353d0EB7e40;
        mock1 = new MerkleTreeMock1(20,hasher);
        mock2 = new MerkleTreeMock2(20,hasher);
        mock1.initialize();
        mock2.initialize();
    }

    // function testMock12() public {
    //     uint256 size;
    //     assembly{
    //         size := extcodesize(0x8D08ac9a511581C7e5BDf8CEd27b7353d0EB7e40)
    //     }
    //     console.log(size);

    //     bytes32 ok1 = bytes32(uint256(5613535123123));
    //     bytes32 ok2 = bytes32(uint256(5645345315442));
    //     uint32 index1 = mock1.insert(ok1,ok2);
    //     console.log(index1);

    //     bytes32 ok3 = bytes32(uint256(561355153513515323123));
    //     bytes32 ok4 = bytes32(uint256(553156453453353115442));
    //     uint32 index2 = mock1.insert(ok3,ok4);
    //     console.log(index2);
    //     // console.logBytes32(ok1);
    //     // console.logBytes32(ok2);
    // }

    function testMock1() public {
        bytes32 ok1 = bytes32(uint256(5613535123123));
        bytes32 ok2 = bytes32(uint256(5645345315442));
        uint32 index1 = mock1.insert(ok1, ok2);
        console.log(index1);
        bytes32 ok3 = bytes32(uint256(561355153513515323123));
        bytes32 ok4 = bytes32(uint256(553156453453353115442));
        uint32 index2 = mock1.insert(ok3, ok4);
        console.log(index2);
    }

    function testMock2() public {
        bytes32 ok1 = bytes32(uint256(5613535123123));
        bytes32 ok2 = bytes32(uint256(5645345315442));
        uint32 index1 = mock2.insert(ok1, ok2);
        console.log(index1);
        console.log(mock2.filledSubtree());
        bytes32 ok3 = bytes32(uint256(561355153513515323123));
        bytes32 ok4 = bytes32(uint256(553156453453353115442));
        uint32 index2 = mock2.insert(ok3, ok4);
        console.log(index2);
        console.log(mock2.filledSubtree());
    }
}
