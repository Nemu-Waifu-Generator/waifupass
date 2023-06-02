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
    string public baseURI =
        "ipfs://bafybeierhfoa46rq5b33sya66d2eelhfbyf4hbtqh75kjgki2isrcks7fi/";
    string public unrevealedURI = "ipfs://";
    bool public useFancyMath = true;
    uint256 public lastTokenRevealed;
    uint256 public startSale;

    mapping(address => uint256) public amtMintedByAddress;

    constructor(uint256 _startSale) ERC721A("Nemu Pass", "NEMU") {
        startSale = _startSale;
    }

    function mint(uint256 _amount) public payable {
        require(block.timestamp >= startSale, "sale hasn't started");
        require(totalSupply() + _amount <= TOKEN_LIMIT, "minted over supply");
        require(
            amtMintedByAddress[msg.sender] + _amount <= 10,
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
        bool _useFancyMath
    ) external onlyRealOwner {
        baseURI = _baseURI;
        useFancyMath = _useFancyMath;
    }

    function retrieveFunds(address payable _to) external onlyRealOwner {
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
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
    function revealBatch() external onlyRealOwner {
        require(
            totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE),
            "totalSupply too low"
        );
        uint256 batchNumber = lastTokenRevealed / REVEAL_BATCH_SIZE;
        bytes32 seed = keccak256(
            abi.encodePacked(blockhash(block.number), block.prevrandao)
        );
        batchToSeed[batchNumber] =
            uint256(seed) %
            (TOKEN_LIMIT - (batchNumber * REVEAL_BATCH_SIZE));
        unchecked {
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
    }
}
