// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./YoyoSeeder.sol";
import "./YoyoDescriptor.sol";

/**
 * @title YoyoToken
 * @notice ERC‑721 token for the YOYO DAO project. Each address can mint exactly one NFT.
 * @dev Minting is controlled by `mintEnabled`. Metadata and trait generation are delegated to
 * separate contracts (`YoyoDescriptor` and `YoyoSeeder`) so that the collection can be
 * upgraded without redeploying the core token.
 */
contract YoyoToken is ERC721, ERC2981, Ownable, ReentrancyGuard {
    /// @dev total number of tokens minted so far
    uint256 public totalSupply;

    /// @dev maximum number of tokens that can be minted (0 = unlimited)
    uint256 public immutable MAX_SUPPLY;

    /// @dev cost to mint one NFT (in wei). Can be set to zero for free mint.
    uint256 public mintPrice;

    /// @dev flag indicating whether public minting is enabled
    bool public mintEnabled = true;

    /// @dev trait seeder contract (generates random trait indices)
    YoyoSeeder public seeder;

    /// @dev metadata descriptor contract
    YoyoDescriptor public descriptor;

    /// @dev mapping to enforce 1 mint per wallet
    mapping(address => bool) public minted;

    /// @dev store the generated seed for each token (trait indices)
    mapping(uint256 => YoyoSeeder.Seed) public seeds;

    /// @dev emitted whenever a token is minted
    event Minted(address indexed to, uint256 indexed tokenId, YoyoSeeder.Seed seed);

    /**
     * @param _maxSupply Maximum supply (0 for unlimited)
     * @param _royaltyFeeBps Fee in basis points for ERC2981 royalties (e.g. 500 = 5%)
     * @param _royaltyReceiver Recipient of the royalty payments
     * @param _seeder Address of the YoyoSeeder contract
     * @param _descriptor Address of the YoyoDescriptor contract
     * @param _mintPrice Price per mint in wei
     */
    constructor(
        uint256 _maxSupply,
        uint96 _royaltyFeeBps,
        address _royaltyReceiver,
        address _seeder,
        address _descriptor,
        uint256 _mintPrice
    ) ERC721("YOYO DAO", "YOYO") {
        MAX_SUPPLY = _maxSupply;
        seeder = YoyoSeeder(_seeder);
        descriptor = YoyoDescriptor(_descriptor);
        mintPrice = _mintPrice;
        // set default royalty for all tokens
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeBps);
    }

    /**
     * @notice Mint one NFT per wallet. Reverts if minting is disabled or supply cap is reached.
     */
    function mintOnce() external payable nonReentrant {
        require(mintEnabled, "Mint disabled");
        require(!minted[msg.sender], "Already minted");
        if (mintPrice > 0) {
            require(msg.value >= mintPrice, "Insufficient ETH");
        }
        if (MAX_SUPPLY != 0) {
            require(totalSupply < MAX_SUPPLY, "Max supply reached");
        }
        uint256 tokenId = ++totalSupply;
        _safeMint(msg.sender, tokenId);
        // generate trait seed
        YoyoSeeder.Seed memory seed = seeder.generateSeed(tokenId, msg.sender);
        seeds[tokenId] = seed;
        minted[msg.sender] = true;
        emit Minted(msg.sender, tokenId, seed);
        // refund excess ETH
        if (mintPrice > 0 && msg.value > mintPrice) {
            uint256 refund = msg.value - mintPrice;
            (bool ok, ) = msg.sender.call{value: refund}("");
            require(ok, "Refund failed");
        }
    }

    /** owner: enable or disable public minting */
    function setMintEnabled(bool _enabled) external onlyOwner {
        mintEnabled = _enabled;
    }

    /** owner: update mint price */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /** owner: update the seeder contract */
    function setSeeder(address _seeder) external onlyOwner {
        seeder = YoyoSeeder(_seeder);
    }

    /** owner: update the descriptor contract */
    function setDescriptor(address _descriptor) external onlyOwner {
        descriptor = YoyoDescriptor(_descriptor);
    }

    /**
     * @notice Withdraw all ETH collected from minting to a specified address.
     * @param to The address to send the funds to.
     */
    function withdraw(address payable to) external onlyOwner {
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    /**
     * @inheritdoc ERC721
     * @dev Returns a Base64-encoded JSON URI generated via YoyoDescriptor.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @inheritdoc ERC721
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
