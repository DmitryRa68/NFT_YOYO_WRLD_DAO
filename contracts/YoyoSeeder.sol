// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title YoyoSeeder
 * @notice Generates pseudo‑random trait indices for YOYO NFTs. Each trait (shoes, pants, shirt,
 * hoodie, face, hair, yo-yo) can have a variable number of variations. Update counts via
 * `setCounts()` to match the number of files in your art folders.
 */
contract YoyoSeeder is Ownable {
    /// Trait combination for one NFT
    struct Seed {
        uint8 shoes;
        uint8 pants;
        uint8 shirt;
        uint8 hoodie;
        uint8 face;
        uint8 hair;
        uint8 yoyo;
    }

    // number of variations for each trait
    uint8 public shoesCount = 1;
    uint8 public pantsCount = 1;
    uint8 public shirtCount = 1;
    uint8 public hoodieCount = 1;
    uint8 public faceCount = 1;
    uint8 public hairCount = 1;
    uint8 public yoyoCount = 1;

    /**
     * @notice Generate a seed using token ID, minter address, and block randomness
     * @param tokenId Token ID being minted
     * @param minter Address of the account minting
     */
    function generateSeed(uint256 tokenId, address minter) external view returns (Seed memory) {
        bytes32 rand = keccak256(abi.encodePacked(tokenId, minter, block.prevrandao, block.timestamp));
        return Seed({
            shoes:  uint8(uint256(rand)         % shoesCount),
            pants:  uint8(uint256(rand >> 32)   % pantsCount),
            shirt:  uint8(uint256(rand >> 64)   % shirtCount),
            hoodie: uint8(uint256(rand >> 96)   % hoodieCount),
            face:   uint8(uint256(rand >> 128)  % faceCount),
            hair:   uint8(uint256(rand >> 160)  % hairCount),
            yoyo:   uint8(uint256(rand >> 192)  % yoyoCount)
        });
    }

    /**
     * @notice Set the number of variations for each trait. Only callable by the owner.
     */
    function setCounts(
        uint8 _shoes,
        uint8 _pants,
        uint8 _shirt,
        uint8 _hoodie,
        uint8 _face,
        uint8 _hair,
        uint8 _yoyo
    ) external onlyOwner {
        shoesCount = _shoes;
        pantsCount = _pants;
        shirtCount = _shirt;
        hoodieCount = _hoodie;
        faceCount = _face;
        hairCount = _hair;
        yoyoCount = _yoyo;
    }
}
