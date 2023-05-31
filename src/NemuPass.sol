// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721A} from "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./forks/BatchReveal.sol";
import "./forks/MultiSigOwnable.sol";

/*
    Forked from 0xngmi's Tubbies.sol
    https://github.com/0xngmi/tubbies/blob/master/contracts/Tubbies.sol
*/

contract NemuPass is ERC721A, MultisigOwnable, BatchReveal {
    string public baseURI;
    string public unrevealedURI;
    bool public useFancyMath;
    uint256 public lastTokenRevealed;
    uint256 public lastBlockForRandom;
    uint256 public maxMint;
    uint256 public startSale;

    mapping(address => uint256) public amtMintedByAddress;

    constructor(
        string memory _baseURI,
        string memory _unrevealedURI,
        bool _useFancyMath,
        uint256 _maxMint,
        uint256 _startSale
    ) ERC721A("Nemu Pass", "NEMU") {
        baseURI = _baseURI;
        unrevealedURI = _unrevealedURI;
        useFancyMath = _useFancyMath;
        maxMint = _maxMint;
        startSale = _startSale;
    }

    function mint(uint256 _amount) public payable {
        require(block.timestamp >= startSale, "sale hasn't started");
        require(totalSupply() + _amount <= TOKEN_LIMIT, "minted over supply");
        require(
            amtMintedByAddress[msg.sender] + _amount <= maxMint,
            "can't mint more than allowed"
        );
        uint256 cost;
        unchecked {
            cost = _amount * 0.1 ether;
        }
        require(msg.value == cost, "wrong payment");
        unchecked {
            amtMintedByAddress[msg.sender] += _amount;
        }
        _mint(msg.sender, _amount);
    }

    function setParams(
        string memory _baseURI,
        string memory _unrevealedURI,
        bool _useFancyMath,
        uint256 _maxMint
    ) external onlyRealOwner {
        baseURI = _baseURI;
        unrevealedURI = _unrevealedURI;
        useFancyMath = _useFancyMath;
        maxMint = _maxMint;
    }

    function retrieveFunds(address payable _to) external onlyRealOwner {
        _to.transfer(address(this).balance);
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
