// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./YoyoSeeder.sol";

/**
 * @title Base64
 * @notice Library for Base64 encoding. Used to encode JSON metadata.
 */
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = string(TABLE);
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(add(result, add(encodedLen, 32)), 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(add(result, add(encodedLen, 32)), 1), shl(248, 0x3d)) }
        }
        return result;
    }
}

/**
 * @title YoyoDescriptor
 * @notice Generates Base64‑encoded metadata JSON for YOYO NFTs. This version uses an off‑chain
 * `imageBaseURI` for the PNG artwork and constructs JSON with human‑readable trait names.
 */
contract YoyoDescriptor {
    /// @dev base URI pointing to the folder where token images are stored (must end with a slash)
    string public imageBaseURI;

    /// @dev collection‑wide description
    string public collectionDescription;

    /// @dev external URL pointing to a website or marketplace listing
    string public externalBase;

    constructor(
        string memory _imageBaseURI,
        string memory _collectionDescription,
        string memory _externalBase
    ) {
        imageBaseURI = _imageBaseURI;
        collectionDescription = _collectionDescription;
        externalBase = _externalBase;
    }

    /** owner: update the base URI for images */
    function setImageBaseURI(string calldata uri) external {
        imageBaseURI = uri;
    }

    /** owner: update the collection description */
    function setCollectionDescription(string calldata desc) external {
        collectionDescription = desc;
    }

    /** owner: update the external URL */
    function setExternalBase(string calldata uri) external {
        externalBase = uri;
    }

    /**
     * @notice Construct the tokenURI for a given token and seed. Combines imageBaseURI with the
     * token ID to form the PNG URL and encodes attributes derived from the seed.
     * @param tokenId ID of the token being queried
     * @param seed Generated trait indices for this token
     */
    function tokenURI(uint256 tokenId, YoyoSeeder.Seed memory seed) external view returns (string memory) {
        string memory imageURI = string(abi.encodePacked(imageBaseURI, _toString(tokenId), ".png"));
        bytes memory json = abi.encodePacked(
            '{"name":"YOYO #', _toString(tokenId),
            '","description":"', collectionDescription,
            '","external_url":"', externalBase,
            '","image":"', imageURI,
            '","attributes":', _attributes(seed), '}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @dev Construct JSON array of attribute objects from a seed. Trait names are hard‑coded here.
     * You should update the names to match your actual assets.
     */
    function _attributes(YoyoSeeder.Seed memory s) internal pure returns (string memory) {
        string[8] memory shoeNames = ["Sneaker1","Sneaker2","Sneaker3","Sneaker4","Sneaker5","Sneaker6","Sneaker7","Sneaker8"];
        string[8] memory pantsNames = ["Pants1","Pants2","Pants3","Pants4","Pants5","Pants6","Pants7","Pants8"];
        string[8] memory shirtNames = ["Shirt1","Shirt2","Shirt3","Shirt4","Shirt5","Shirt6","Shirt7","Shirt8"];
        string[8] memory hoodieNames = ["Hoodie1","Hoodie2","Hoodie3","Hoodie4","Hoodie5","Hoodie6","Hoodie7","Hoodie8"];
        string[8] memory faceNames = ["Face1","Face2","Face3","Face4","Face5","Face6","Face7","Face8"];
        string[8] memory hairNames = ["Hair1","Hair2","Hair3","Hair4","Hair5","Hair6","Hair7","Hair8"];
        string[8] memory yoyoNames = ["YoYo1","YoYo2","YoYo3","YoYo4","YoYo5","YoYo6","YoYo7","YoYo8"];
        return string(
            abi.encodePacked(
                '[{"trait_type":"Shoes","value":"', shoeNames[s.shoes], '"},',
                '{"trait_type":"Pants","value":"', pantsNames[s.pants], '"},',
                '{"trait_type":"Shirt","value":"', shirtNames[s.shirt], '"},',
                '{"trait_type":"Hoodie","value":"', hoodieNames[s.hoodie], '"},',
                '{"trait_type":"Face","value":"', faceNames[s.face], '"},',
                '{"trait_type":"Hair","value":"', hairNames[s.hair], '"},',
                '{"trait_type":"YoYo","value":"', yoyoNames[s.yoyo], '"}]'
            )
        );
    }

    /**
     * @dev Convert a uint256 to a decimal string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
