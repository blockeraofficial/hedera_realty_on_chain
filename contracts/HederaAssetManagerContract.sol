// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract HederaAssetManagerContract is Ownable, ReentrancyGuard {

    /// Emitted when a purchase completes
    event Purchased(address indexed token, address indexed buyer, uint256 assetTokenAmount, uint256 totalPaidHBAR);

    /// Emitted when price is set/updated for a token
    event PriceSet(address indexed token, uint256 pricePerWholeHBAR);

    /// Emitted when the global default price is updated
    event GlobalPriceSet(uint256 pricePerWholeHBAR);

    /// Emitted when payout treasury is updated
    event TreasuryUpdated(address newTreasury);

    /// Emitted on pause state changes
    event Paused(bool paused);

    // ----- Config -----

    // Payout wallet for HBAR revenue  // Which will be the smart contract itself at first
    address public treasury;

    // Pause flag
    bool public paused;

    // Mapping: token (EVM addr) => price per WHOLE token in HBAR (EVM wei; 1 HBAR = 1e18)
    mapping(address => uint256) public pricePerWhole;

    // Global default price per WHOLE token (applies if a token has no specific price)
    uint256 public globalPricePerWhole;

    // HBAR scalar (EVM)
    uint256 private constant HBAR_WEI = 1e18;

    // ----- Constructor -----

    constructor() Ownable(msg.sender) {

        treasury = address(this);

        // Default: 100 HBAR per whole token
        globalPricePerWhole = 100 * HBAR_WEI;
        emit GlobalPriceSet(globalPricePerWhole);
        emit TreasuryUpdated(address(this));
    }

    // ----- Admin (onlyOwner) ----- 

    // Set each of the tokenized asset price over here

    function setPrice(address assetToken, uint256 hbarPerWhole) external onlyOwner {
        require(assetToken != address(0), "token=0");
        require(hbarPerWhole > 0, "price=0");
        pricePerWhole[assetToken] = hbarPerWhole;
        emit PriceSet(assetToken, hbarPerWhole);
    }

    /// Set the global default price per WHOLE token (used when a token has no specific price)
    function setGlobalPrice(uint256 hbarPerWhole) external onlyOwner {
        require(hbarPerWhole > 0, "price=0");
        globalPricePerWhole = hbarPerWhole;
        emit GlobalPriceSet(hbarPerWhole);
    }

    /// Update HBAR payout wallet
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "treasury=0");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    /// Pause/unpause purchases
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /// Withdraw HBAR revenue
    function withdrawHBAR(uint256 amount, address to) external onlyOwner nonReentrant {
        (bool ok, ) = payable(to).call{value: amount}("");
        require(ok, "HBAR withdraw failed");
    }

    /// Withdraw unsold tokenized asset inventory
    function withdrawInventory(address assetToken, uint256 baseUnits, address to) external onlyOwner nonReentrant {
        require(IERC20(assetToken).transfer(to, baseUnits), "token withdraw failed");
    }

    receive() external payable {}

    // ----- Helpers (views) -----

    /// Quote total price in HBAR wei for `assetTokenAmount` of `assetToken`
    function quotePrice(address assetToken, uint256 assetTokenAmount) external view returns (uint256 totalHBARWei) {
        uint256 unitPrice = _unitPrice(assetToken);
        return unitPrice * assetTokenAmount;
    }

    /// Convert whole units to base units using `decimals()`
    function baseUnitsForWhole(address assetToken, uint256 assetTokenAmount) public view returns (uint256) {
        uint8 decimals = IERC20Metadata(assetToken).decimals();
        return assetTokenAmount * (10 ** uint256(decimals));
    }

    /// Buy `assetTokenAmount` of `assetToken` by paying exact HBAR.
    /// Contract must already hold sufficient inventory of `assetToken`.
    /// HTS token EVM address for the tokenized asset (dynamic per asset)
    /// Number of WHOLE tokens (e.g., 1 == one token; not base units)

    function buy_realty_fraction(address assetToken, uint64 assetTokenAmount)
        external
        payable
        nonReentrant
    {
        require(!paused, "paused");
        require(assetToken != address(0), "token=0");
        require(assetTokenAmount > 0, "amount=0");

        // 1) Price check (HBAR)
        uint256 unitPrice = _unitPrice(assetToken);
        uint256 total = unitPrice * uint256(assetTokenAmount);
        require(msg.value == total, "wrong HBAR sent");

        // 2) Convert WHOLE -> base units
        uint256 baseUnits = baseUnitsForWhole(assetToken, uint256(assetTokenAmount));

        // 3) Inventory check (optional but user-friendly)
        require(IERC20(assetToken).balanceOf(address(this)) >= baseUnits, "Insufficient inventory");

        // 4) Deliver from contract’s own balance
        require(IERC20(assetToken).transfer(msg.sender, baseUnits), "Deliver failed");

        // 5) Forward HBAR to treasury (or keep in contract and withdraw later if you prefer)
        (bool ok, ) = payable(treasury).call{value: msg.value}("");
        require(ok, "HBAR forward failed");

        emit Purchased(assetToken, msg.sender, uint256(assetTokenAmount), msg.value);
    }

    // ----- Internal -----

    function _unitPrice(address assetToken) internal view returns (uint256) {
        uint256 p = pricePerWhole[assetToken];
        return p == 0 ? globalPricePerWhole : p;
    }

}