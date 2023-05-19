// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721A} from "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./forks/BatchReveal.sol";
import "./forks/MultiSigOwnable.sol";

/*
    Forked from 0xngmi's Tubbies.sol
    https://github.com/0xngmi/tubbies/blob/master/contracts/Tubbies.sol
*/

contract NemuPass is ERC721A, MultisigOwnable, BatchReveal {
    uint256 public immutable startSale;
    string public baseURI;
    string public unrevealedURI = "ipfs://";
    bool public useFancyMath = true;
    uint256 public lastTokenRevealed = 0;
    uint256 public lastBlockForRandom;
    uint256 public currentMaxSupply;

    constructor(
        uint256 _startSale,
        string memory _baseURI,
        uint256 _initialMaxSupply
    ) ERC721A("Nemu Pass", "NEMU") {
        startSale = _startSale;
        baseURI = _baseURI;
        currentMaxSupply = _initialMaxSupply;
    }

    function mint(uint256 _amount) public payable {
        require(block.timestamp >= startSale, "sale has not started");
        require(totalSupply() + _amount <= currentMaxSupply, "minted over supply");
        uint256 cost;
        unchecked {
            cost = _amount * 0.1 ether;
        }
        require(msg.value == cost, "wrong payment");
        _mint(msg.sender, _amount);
    }

    function setParams(
        string memory newBaseURI,
        string memory newUnrevealedURI,
        bool newUseFancyMath,
        uint256 newCurrentMaxSupply
    ) external onlyRealOwner {
        require(newCurrentMaxSupply >= currentMaxSupply && newCurrentMaxSupply <= TOKEN_LIMIT);
        baseURI = newBaseURI;
        unrevealedURI = newUnrevealedURI;
        useFancyMath = newUseFancyMath;
        currentMaxSupply = newCurrentMaxSupply;
    }

    function retrieveFunds(address payable to) external onlyRealOwner {
        to.transfer(address(this).balance);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!useFancyMath) {
            return string(abi.encodePacked(baseURI, Strings.toString(id)));
        }
        if (id >= lastTokenRevealed) {
            return unrevealedURI;
        } else {
            uint batch = id / REVEAL_BATCH_SIZE;
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(getShuffledTokenId(id, batch)),
                        ".json"
                    )
                );
        }
    }

    /*
        THIS IS NOT TRULY RANDOM AND IS PSUEDO RANDOM 
        BLOCKCHAINS ARE DETERMINISTIC
        YOU SHOULD USE CHAINLINK VRF IF YOU ACTUALLY NEED IT
    */
    function requestBlock() external onlyRealOwner {
        require(
            totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE),
            "totalSupply too low"
        );
        lastBlockForRandom = block.number;
    }

    function revealBatch() external onlyRealOwner {
        require(
            totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE),
            "totalSupply too low"
        );
        uint256 batchNumber = lastTokenRevealed / REVEAL_BATCH_SIZE;
        bytes32 seed = keccak256(
            abi.encodePacked(
                block.number - lastBlockForRandom,
                block.prevrandao,
                block.timestamp
            )
        );
        batchToSeed[batchNumber] =
            uint256(seed) %
            (TOKEN_LIMIT - (batchNumber * REVEAL_BATCH_SIZE));
        unchecked {
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
    }
}
