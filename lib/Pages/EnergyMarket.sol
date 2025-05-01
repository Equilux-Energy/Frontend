// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EnergyToken.sol";
import "./EnergyEscrow.sol";
import "./PriceTracker.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title EnergyMarketplace
 * @dev Main contract for the peer-to-peer energy trading platform with hash-based IDs
 */
contract EnergyMarketplace is
    ReentrancyGuard,
    Pausable,
    AccessControl,
    Ownable
{
    // Define roles for contract access
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    // Add a dispute period
    uint256 public constant DISPUTE_PERIOD = 24 hours;

    // Funding timeout: buyer must fund within 24 hours
    uint256 public constant FUNDING_TIMEOUT = 1 hours;

    // Reference to the price tracker contract
    PriceTracker public priceTracker;

    // Reference to the energy token
    EnergyToken public energyToken;

    // Reference to the escrow contract
    EnergyEscrow public escrowContract;

    // Maximum username length to prevent gas issues
    uint256 public constant MAX_USERNAME_LENGTH = 32;

    // Mapping to store usernames by address
    mapping(address => string) public usernames;

    // Mapping from username to address to check if username exists
    mapping(string => address) private usernameToAddress;

    // New struct to track user statistics and history
    struct UserProfile {
        uint256 offersCreated;
        uint256 offersCountered;
        uint256 agreementsCompleted;
        uint256 agreementsCancelled;
        uint256 disputesInitiated;
        uint256 disputesWon;
        uint256 totalEnergyTraded;
        uint256 totalValueTraded;
        uint256 lastActivityTimestamp;
    }

    // Mapping to store user profiles
    mapping(address => UserProfile) public userProfiles;

    // Events for username registration
    event UsernameRegistered(address indexed user, string username);
    event UsernameUpdated(
        address indexed user,
        string oldUsername,
        string newUsername
    );

    // Enum for offer type
    enum OfferType {
        BUY,
        SELL
    }

    // Enum for offer status
    enum OfferStatus {
        ACTIVE,
        COUNTERED,
        AGREED,
        IN_PROGRESS,
        COMPLETED,
        CANCELLED
    }

    // Struct to track milestone completion
    struct MilestoneCompletion {
        uint256 timestamp;
        bool canDispute;
        bool disputed;
    }

    // Struct to represent an energy trading offer
    struct Offer {
        bytes32 id;
        address creator;
        string creatorUsername;
        OfferType offerType;
        uint256 energyAmount; // in kWh
        uint256 pricePerUnit; // price in tokens per kWh
        uint256 totalPrice;
        uint256 startTime;
        uint256 endTime;
        OfferStatus status;
        address counterparty;
        string counterpartyUsername;
        uint256 createdAt;
    }

    // Struct to represent a counter-offer
    struct CounterOffer {
        bytes32 id; // Add unique ID
        address sender;
        string senderUsername;
        uint256 timestamp;
        uint256 proposedEnergyAmount;
        uint256 proposedPricePerUnit;
        uint256 proposedTotalPrice;
        bool isActive; // Whether this counter offer is still active
    }

    // Struct to represent a trade agreement
    struct Agreement {
        bytes32 id;
        bytes32 offerId;
        address buyer;
        string buyerUsername;
        address seller;
        string sellerUsername;
        uint256 finalEnergyAmount;
        uint256 finalTotalPrice;
        uint256 agreedAt;
        bytes32 escrowId;
        bool isActive;
        uint256 fundingDeadline;
        bool funded;
        mapping(uint256 => MilestoneCompletion) milestones;
    }

    // Counter for nonce (used to ensure unique IDs)
    uint256 private nonce = 0;

    // Mapping from offer ID to Offer
    mapping(bytes32 => Offer) public offers;

    // Mapping from offer ID to counter offers by address
    mapping(bytes32 => mapping(address => CounterOffer[]))
        public counterOffersByAddress;

    // Mapping from offer ID to list of addresses that have made counter offers
    mapping(bytes32 => address[]) public offerCounterParties;

    // Mapping from agreement ID to Agreement
    mapping(bytes32 => Agreement) public agreements;

    // Mapping of user address to their created offers
    mapping(address => bytes32[]) public userOffers;

    // Mapping of user address to their agreements
    mapping(address => bytes32[]) public userAgreements;

    // Set of all active offer IDs
    bytes32[] public activeOfferIds;
    mapping(bytes32 => uint256) private activeOfferIndexes;

    // Add a mapping to look up counter offers by their ID
    mapping(bytes32 => CounterOffer) public counterOffersById;

    // Events
    event OfferCreated(
        bytes32 indexed offerId,
        address indexed creator,
        string creatorUsername,
        OfferType offerType
    );

    event OfferUpdated(bytes32 indexed offerId, OfferStatus status);

    event CounterOfferCreated(
        bytes32 indexed offerId,
        bytes32 indexed counterOfferId, // Add counter offer ID
        address indexed sender,
        string senderUsername,
        uint256 proposedEnergyAmount,
        uint256 proposedPricePerUnit,
        uint256 proposedTotalPrice
    );

    event CounterOfferAccepted(
        bytes32 indexed offerId,
        bytes32 indexed counterOfferId, // Add counter offer ID
        address indexed counterparty,
        string counterpartyUsername,
        uint256 finalEnergyAmount,
        uint256 finalPricePerUnit,
        uint256 finalTotalPrice
    );

    event CounterOfferRejected(
        bytes32 indexed offerId,
        bytes32 indexed counterOfferId, // Add counter offer ID
        address indexed counterparty,
        string counterpartyUsername
    );

    event DirectOfferAccepted(
        bytes32 indexed offerId,
        address indexed counterparty,
        string counterpartyUsername
    );

    event AgreementCreated(
        bytes32 indexed agreementId,
        bytes32 indexed offerId,
        address buyer,
        string buyerUsername,
        address seller,
        string sellerUsername
    );

    event EnergyDeliveryProgress(
        bytes32 indexed agreementId,
        uint256 percentage
    );

    event TradeCompleted(bytes32 indexed agreementId);

    event TradeRefunded(bytes32 indexed agreementId, string reason);

    event MilestoneDisputed(
        bytes32 indexed agreementId,
        uint256 percentage,
        string reason
    );

    event AgreementFunded(bytes32 indexed agreementId);

    event AgreementCancelled(bytes32 indexed agreementId, string reason);

    /**
     * @dev Constructor to set the energy token address
     * @param _tokenAddress Address of the energy token contract
     */
    constructor(address _tokenAddress) Ownable(msg.sender) {
        energyToken = EnergyToken(_tokenAddress);
        escrowContract = new EnergyEscrow(address(energyToken));
        priceTracker = new PriceTracker(); // Create new price tracker

        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Register or update a username for the calling user
     * @param _username The username to register
     */
    function registerUsername(
        string calldata _username
    ) external whenNotPaused onlyRole(USER_ROLE) {
        require(bytes(_username).length > 0, "Username Invalid");
        require(
            bytes(_username).length <= MAX_USERNAME_LENGTH,
            "Username long"
        );
        require(
            usernameToAddress[_username] == address(0) ||
                usernameToAddress[_username] == msg.sender,
            "Username Taken"
        );

        // Check if user is updating an existing username
        string memory oldUsername = usernames[msg.sender];

        if (bytes(oldUsername).length > 0) {
            // Clear old username mapping
            delete usernameToAddress[oldUsername];
            emit UsernameUpdated(msg.sender, oldUsername, _username);
        } else {
            emit UsernameRegistered(msg.sender, _username);
        }

        // Update mappings
        usernames[msg.sender] = _username;
        usernameToAddress[_username] = msg.sender;

        // Initialize user profile if it doesn't exist
        if (userProfiles[msg.sender].lastActivityTimestamp == 0) {
            userProfiles[msg.sender] = UserProfile({
                offersCreated: 0,
                offersCountered: 0,
                agreementsCompleted: 0,
                agreementsCancelled: 0,
                disputesInitiated: 0,
                disputesWon: 0,
                totalEnergyTraded: 0,
                totalValueTraded: 0,
                lastActivityTimestamp: block.timestamp
            });
        } else {
            userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;
        }
    }

    /**
     * @dev Get a user's username
     * @param _user The address of the user
     * @return The username associated with the address, or empty if not registered
     */
    function getUsernameByAddress(
        address _user
    ) public view returns (string memory) {
        return usernames[_user];
    }

    /**
     * @dev Get a user's address by their username
     * @param _username The username to look up
     * @return The address associated with the username, or zero address if not registered
     */
    function getAddressByUsername(
        string calldata _username
    ) public view returns (address) {
        return usernameToAddress[_username];
    }

    /**
     * @dev Generate a unique hash-based ID
     * @param _creator Address of the creator
     * @param _salt Additional salt value
     * @return bytes32 hash that serves as ID
     */
    function generateUniqueId(
        address _creator,
        uint256 _salt
    ) internal returns (bytes32) {
        nonce++;
        return
            keccak256(
                abi.encodePacked(
                    _creator,
                    block.timestamp,
                    _salt,
                    nonce,
                    blockhash(block.number - 1)
                )
            );
    }

    /**
     * @dev Create a new energy trading offer
     * @param _offerType Type of the offer (BUY or SELL)
     * @param _energyAmount Amount of energy in kWh
     * @param _pricePerUnit Price per kWh in tokens
     * @param _startTime Start time for energy delivery
     * @param _endTime End time for energy delivery
     * @return offerId Hash ID of the created offer
     */
    function createOffer(
        OfferType _offerType,
        uint256 _energyAmount,
        uint256 _pricePerUnit,
        uint256 _startTime,
        uint256 _endTime
    )
        external
        whenNotPaused
        nonReentrant
        onlyRole(USER_ROLE)
        returns (bytes32 offerId)
    {
        require(_energyAmount > 0, "Amount must be > 0");
        require(_pricePerUnit > 0, "Price must be > 0");
        require(_endTime > _startTime, "End time must be after start time");
        require(_startTime > block.timestamp, "Start time must be in future");

        // Ensure user has registered a username
        string memory creatorUsername = usernames[msg.sender];
        require(
            bytes(creatorUsername).length > 0,
            "Must register username first"
        );

        uint256 totalPrice = _energyAmount * _pricePerUnit;
        offerId = generateUniqueId(msg.sender, uint256(uint160(_offerType)));
        offers[offerId] = Offer({
            id: offerId,
            creator: msg.sender,
            creatorUsername: creatorUsername,
            offerType: _offerType,
            energyAmount: _energyAmount,
            pricePerUnit: _pricePerUnit,
            totalPrice: totalPrice,
            startTime: _startTime,
            endTime: _endTime,
            status: OfferStatus.ACTIVE,
            counterparty: address(0),
            counterpartyUsername: "",
            createdAt: block.timestamp
        });

        userOffers[msg.sender].push(offerId);
        activeOfferIds.push(offerId);
        activeOfferIndexes[offerId] = activeOfferIds.length - 1;

        // Update user profile statistics
        UserProfile storage profile = userProfiles[msg.sender];
        profile.offersCreated += 1;
        profile.lastActivityTimestamp = block.timestamp;

        emit OfferCreated(offerId, msg.sender, creatorUsername, _offerType);
        return offerId;
    }

    /**
     * @dev Update an existing offer
     * @param _offerId ID of the offer
     * @param _energyAmount Amount of energy in kWh
     * @param _pricePerUnit Price per kWh in tokens
     * @param _startTime Start time for energy delivery
     * @param _endTime End time for energy delivery
     */
    function updateOffer(
        bytes32 _offerId,
        uint256 _energyAmount,
        uint256 _pricePerUnit,
        uint256 _startTime,
        uint256 _endTime
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(msg.sender == offer.creator, "Only creator can update offer");
        require(
            offer.status == OfferStatus.ACTIVE ||
                offer.status == OfferStatus.COUNTERED,
            "Offer cannot be updated"
        );

        // Validate inputs
        require(_energyAmount > 0, "Energy amount must be > 0");
        require(_pricePerUnit > 0, "Price per unit must be > 0");
        require(_endTime > _startTime, "End time must be after start time");
        require(
            _startTime > block.timestamp,
            "Start time must be in the future"
        );

        // Update the offer
        offer.energyAmount = _energyAmount;
        offer.pricePerUnit = _pricePerUnit;
        offer.totalPrice = _energyAmount * _pricePerUnit;
        offer.startTime = _startTime;
        offer.endTime = _endTime;

        // Update user profile's last activity timestamp
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;

        emit OfferUpdated(_offerId, offer.status);
    }

    /**
     * @dev Create a counter offer for an existing offer
     * @param _offerId ID of the offer
     * @param _proposedEnergyAmount Proposed amount of energy in kWh
     * @param _proposedPricePerUnit Proposed price per kWh in tokens
     */
    function createCounterOffer(
        bytes32 _offerId,
        uint256 _proposedEnergyAmount,
        uint256 _proposedPricePerUnit
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(
            offer.status == OfferStatus.ACTIVE ||
                offer.status == OfferStatus.COUNTERED,
            "Offer not open for counter offers"
        );
        require(msg.sender != offer.creator, "Cannot counter your own offer");
        require(_proposedEnergyAmount > 0, "Energy amount must be > 0");
        require(_proposedPricePerUnit > 0, "Price per unit must be > 0");

        // Get username of sender
        string memory senderUsername = usernames[msg.sender];
        require(
            bytes(senderUsername).length > 0,
            "Must register username first"
        );

        // Calculate total price
        uint256 proposedTotalPrice = _proposedEnergyAmount *
            _proposedPricePerUnit;

        // Mark any previous counter offers from this user as inactive
        CounterOffer[] storage userCounterOffers = counterOffersByAddress[
            _offerId
        ][msg.sender];
        for (uint i = 0; i < userCounterOffers.length; i++) {
            userCounterOffers[i].isActive = false;
        }

        // Generate a unique ID for the counter offer
        bytes32 counterOfferId = generateUniqueId(
            msg.sender,
            uint256(_proposedEnergyAmount * _proposedPricePerUnit)
        );

        // Create new counter offer with ID
        CounterOffer memory newCounterOffer = CounterOffer({
            id: counterOfferId,
            sender: msg.sender,
            senderUsername: senderUsername,
            timestamp: block.timestamp,
            proposedEnergyAmount: _proposedEnergyAmount,
            proposedPricePerUnit: _proposedPricePerUnit,
            proposedTotalPrice: proposedTotalPrice,
            isActive: true
        });

        // Add counter offer to existing mappings
        counterOffersByAddress[_offerId][msg.sender].push(newCounterOffer);

        // Add to the ID mapping
        counterOffersById[counterOfferId] = newCounterOffer;

        // If this is the first counter offer from this user, add to counterparty list
        if (userCounterOffers.length == 0) {
            offerCounterParties[_offerId].push(msg.sender);
        }

        // Update offer status if needed
        if (offer.status == OfferStatus.ACTIVE) {
            offer.status = OfferStatus.COUNTERED;
            emit OfferUpdated(_offerId, OfferStatus.COUNTERED);
        }

        // Update user profile stats
        UserProfile storage profile = userProfiles[msg.sender];
        profile.offersCountered += 1;
        profile.lastActivityTimestamp = block.timestamp;

        // Emit event with the counter offer ID
        emit CounterOfferCreated(
            _offerId,
            counterOfferId, // Add counter offer ID to event
            msg.sender,
            senderUsername,
            _proposedEnergyAmount,
            _proposedPricePerUnit,
            proposedTotalPrice
        );
    }

    /**
     * @dev Accept a counter offer
     * @param _offerId ID of the offer
     * @param _counterOfferId ID of the counter offer
     */
    function acceptCounterOffer(
        bytes32 _offerId,
        bytes32 _counterOfferId
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(
            msg.sender == offer.creator,
            "Only creator can accept counter offers"
        );
        require(
            offer.status == OfferStatus.ACTIVE ||
                offer.status == OfferStatus.COUNTERED,
            "Offer not open for acceptance"
        );

        // Get counter offer directly by ID
        CounterOffer storage counterOffer = counterOffersById[_counterOfferId];
        require(
            counterOffer.id == _counterOfferId,
            "Counter offer does not exist"
        );
        require(counterOffer.isActive, "Counter offer is not active");

        // Verify that the counter offer is for this offer
        // We need to check at least one entry in the array matches this ID
        bool isOfferCounterOffer = false;
        CounterOffer[] storage counterOffers = counterOffersByAddress[_offerId][
            counterOffer.sender
        ];
        for (uint256 i = 0; i < counterOffers.length; i++) {
            if (counterOffers[i].id == _counterOfferId) {
                isOfferCounterOffer = true;
                break;
            }
        }
        require(isOfferCounterOffer, "Counter offer is not for this offer");

        // Get counterparty details
        address counterparty = counterOffer.sender;
        string memory counterpartyUsername = counterOffer.senderUsername;

        // Update offer with the accepted terms
        offer.energyAmount = counterOffer.proposedEnergyAmount;
        offer.pricePerUnit = counterOffer.proposedPricePerUnit;
        offer.totalPrice = counterOffer.proposedTotalPrice;
        offer.status = OfferStatus.AGREED;
        offer.counterparty = counterparty;
        offer.counterpartyUsername = counterpartyUsername;

        // Mark the counter offer as inactive
        counterOffer.isActive = false;

        // Remove from active offers
        _removeFromActiveOffers(_offerId);

        // Update user profile's last activity timestamp
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;
        userProfiles[counterparty].lastActivityTimestamp = block.timestamp;

        emit CounterOfferAccepted(
            _offerId,
            _counterOfferId,
            counterparty,
            counterpartyUsername,
            counterOffer.proposedEnergyAmount,
            counterOffer.proposedPricePerUnit,
            counterOffer.proposedTotalPrice
        );
        emit OfferUpdated(_offerId, OfferStatus.AGREED);
    }

    /**
     * @dev Reject a counter offer
     * @param _offerId ID of the offer
     * @param _counterOfferId ID of the counter offer
     */
    function rejectCounterOffer(
        bytes32 _offerId,
        bytes32 _counterOfferId
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(
            msg.sender == offer.creator,
            "Only creator can reject counter offers"
        );
        require(
            offer.status == OfferStatus.ACTIVE ||
                offer.status == OfferStatus.COUNTERED,
            "Offer not open for rejection"
        );

        // Get counter offer directly by ID
        CounterOffer storage counterOffer = counterOffersById[_counterOfferId];
        require(
            counterOffer.id == _counterOfferId,
            "Counter offer does not exist"
        );
        require(counterOffer.isActive, "Counter offer is not active");

        // Verify that the counter offer is for this offer
        bool isOfferCounterOffer = false;
        CounterOffer[] storage counterOffers = counterOffersByAddress[_offerId][
            counterOffer.sender
        ];
        for (uint256 i = 0; i < counterOffers.length; i++) {
            if (counterOffers[i].id == _counterOfferId) {
                isOfferCounterOffer = true;
                break;
            }
        }
        require(isOfferCounterOffer, "Counter offer is not for this offer");

        // Mark the counter offer as inactive
        counterOffer.isActive = false;

        // Get counterparty details
        address counterparty = counterOffer.sender;
        string memory counterpartyUsername = counterOffer.senderUsername;

        // Update user profile's last activity timestamp
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;

        emit CounterOfferRejected(
            _offerId,
            _counterOfferId,
            counterparty,
            counterpartyUsername
        );
    }

    /**
     * @dev Accept an offer directly without counter-offer
     * @param _offerId ID of the offer to accept
     */
    function acceptOfferDirectly(
        bytes32 _offerId
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(
            offer.status == OfferStatus.ACTIVE,
            "Offer not open for direct acceptance"
        );
        require(msg.sender != offer.creator, "Cannot accept your own offer");

        // Get username
        string memory acceptorUsername = usernames[msg.sender];
        require(
            bytes(acceptorUsername).length > 0,
            "Must register username first"
        );

        // Update offer status
        offer.status = OfferStatus.AGREED;
        offer.counterparty = msg.sender;
        offer.counterpartyUsername = acceptorUsername;

        // Remove from active offers
        _removeFromActiveOffers(_offerId);

        // Update user profile's last activity timestamp
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;
        userProfiles[offer.creator].lastActivityTimestamp = block.timestamp;

        emit DirectOfferAccepted(_offerId, msg.sender, acceptorUsername);
        emit OfferUpdated(_offerId, OfferStatus.AGREED);
    }

    /**
     * @dev Create a trade agreement from an agreed offer
     * @param _offerId ID of the offer
     * @return agreementId ID of the created agreement
     */
    function createAgreement(
        bytes32 _offerId
    )
        external
        whenNotPaused
        nonReentrant
        onlyRole(USER_ROLE)
        returns (bytes32)
    {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(
            offer.status == OfferStatus.AGREED,
            "Offer must be agreed upon before creating an agreement"
        );
        require(
            msg.sender == offer.creator || msg.sender == offer.counterparty,
            "Only parties involved in the offer can create an agreement"
        );

        address buyer;
        string memory buyerUsername;
        address seller;
        string memory sellerUsername;

        if (offer.offerType == OfferType.BUY) {
            buyer = offer.creator;
            buyerUsername = offer.creatorUsername;
            seller = offer.counterparty;
            sellerUsername = offer.counterpartyUsername;
        } else {
            seller = offer.creator;
            sellerUsername = offer.creatorUsername;
            buyer = offer.counterparty;
            buyerUsername = offer.counterpartyUsername;
        }

        bytes32 agreementId = generateUniqueId(
            msg.sender,
            uint256(offer.totalPrice)
        );

        // Create a new escrow record for this agreement
        bytes32 escrowId = escrowContract.createEscrow(
            buyer,
            seller,
            offer.energyAmount,
            offer.totalPrice
        );
        priceTracker.recordPriceData(offer.pricePerUnit, offer.energyAmount);
        // Create the agreement
        Agreement storage newAgreement = agreements[agreementId];
        newAgreement.id = agreementId;
        newAgreement.offerId = _offerId;
        newAgreement.buyer = buyer;
        newAgreement.buyerUsername = buyerUsername;
        newAgreement.seller = seller;
        newAgreement.sellerUsername = sellerUsername;
        newAgreement.finalEnergyAmount = offer.energyAmount;
        newAgreement.finalTotalPrice = offer.totalPrice;
        newAgreement.agreedAt = block.timestamp;
        newAgreement.fundingDeadline = block.timestamp + FUNDING_TIMEOUT;
        newAgreement.escrowId = escrowId;
        newAgreement.isActive = true;
        newAgreement.funded = false;

        userAgreements[buyer].push(agreementId);
        userAgreements[seller].push(agreementId);

        // Update activity timestamp for both parties
        userProfiles[buyer].lastActivityTimestamp = block.timestamp;
        userProfiles[seller].lastActivityTimestamp = block.timestamp;

        emit AgreementCreated(
            agreementId,
            _offerId,
            buyer,
            buyerUsername,
            seller,
            sellerUsername
        );

        return agreementId;
    }

    /**
     * @dev Remove an offer from the active offers list
     * @param _offerId ID of the offer to remove
     */
    function _removeFromActiveOffers(bytes32 _offerId) internal {
        uint256 index = activeOfferIndexes[_offerId];
        uint256 lastIndex = activeOfferIds.length - 1;

        if (index != lastIndex) {
            bytes32 lastOfferId = activeOfferIds[lastIndex];
            activeOfferIds[index] = lastOfferId;
            activeOfferIndexes[lastOfferId] = index;
        }

        activeOfferIds.pop();
        delete activeOfferIndexes[_offerId];
    }

    /**
     * @dev Funds an existing agreement
     * @param _agreementId The unique identifier of the agreement to be funded
     */
    function fundAgreement(
        bytes32 _agreementId
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement not active");
        require(!agreement.funded, "Agreement already funded");
        require(
            block.timestamp <= agreement.fundingDeadline,
            "Funding deadline passed"
        );
        require(msg.sender == agreement.buyer, "Only buyer can fund");

        require(
            energyToken.transferFrom(
                agreement.buyer,
                address(escrowContract),
                agreement.finalTotalPrice
            ),
            "Token transfer failed"
        );
        agreement.funded = true;
        escrowContract.startEscrow(agreement.escrowId);

        // Update buyer profile's last activity timestamp
        userProfiles[agreement.buyer].lastActivityTimestamp = block.timestamp;

        emit AgreementFunded(_agreementId);
    }

    /**
     * @dev Start the energy transfer process
     * @param _agreementId ID of the agreement
     */
    function startEnergyTransfer(
        bytes32 _agreementId
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement not active");
        require(agreement.funded, "Agreement not funded");
        require(
            msg.sender == agreement.buyer || msg.sender == agreement.seller,
            "Only buyer or seller can start transfer"
        );

        // Update offer status
        Offer storage offer = offers[agreement.offerId];
        offer.status = OfferStatus.IN_PROGRESS;

        // Update user profile's last activity timestamp
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;

        emit EnergyDeliveryProgress(_agreementId, 0);
        emit OfferUpdated(agreement.offerId, OfferStatus.IN_PROGRESS);
    }

    /**
     * @dev Cancel an unfunded agreement if the funding deadline has expired
     * @param _agreementId The ID of the agreement to cancel
     */
    function cancelUnfundedAgreement(
        bytes32 _agreementId
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement not active");
        require(!agreement.funded, "Agreement already funded");
        require(
            block.timestamp > agreement.fundingDeadline,
            "Funding deadline not expired"
        );

        // Allow buyer, seller, or admin to cancel
        require(
            msg.sender == agreement.buyer ||
                msg.sender == agreement.seller ||
                hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(MODERATOR_ROLE, msg.sender),
            "Not authorized to cancel"
        );

        agreement.isActive = false;

        // Reactivate the original offer
        Offer storage offer = offers[agreement.offerId];
        offer.status = OfferStatus.ACTIVE;
        offer.counterparty = address(0);
        offer.counterpartyUsername = "";
        activeOfferIds.push(offer.id);
        activeOfferIndexes[offer.id] = activeOfferIds.length - 1;

        // Update user statistics
        userProfiles[agreement.buyer].agreementsCancelled += 1;
        userProfiles[agreement.seller].agreementsCancelled += 1;
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;

        emit AgreementCancelled(_agreementId, "Funding deadline expired");
        emit OfferUpdated(offer.id, OfferStatus.ACTIVE);
    }

    /**
     * @dev Report energy delivery progress
     * @param _agreementId ID of the agreement
     * @param _percentage Percentage of energy delivered (25, 50, 75, or 100)
     */
    function reportEnergyDelivery(
        bytes32 _agreementId,
        uint256 _percentage
    ) external whenNotPaused nonReentrant onlyRole(MODERATOR_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement is not active");
        require(
            _percentage == 25 ||
                _percentage == 50 ||
                _percentage == 75 ||
                _percentage == 100,
            "Percentage must be 25, 50, 75, or 100"
        );

        // Release appropriate amount from escrow
        escrowContract.releasePayment(agreement.escrowId, _percentage);

        // Report milestone completion with dispute period
        agreement.milestones[_percentage] = MilestoneCompletion({
            timestamp: block.timestamp,
            canDispute: true,
            disputed: false
        });

        emit EnergyDeliveryProgress(_agreementId, _percentage);

        // If 100% delivered, complete the trade
        if (_percentage == 100) {
            completeAgreement(_agreementId);
        }
    }

    /**
     * @dev Complete an agreement after full delivery
     * @param _agreementId ID of the agreement
     */
    function completeAgreement(bytes32 _agreementId) internal {
        Agreement storage agreement = agreements[_agreementId];
        Offer storage offer = offers[agreement.offerId];

        agreement.isActive = false;
        offer.status = OfferStatus.COMPLETED;

        // Update user statistics
        UserProfile storage buyerProfile = userProfiles[agreement.buyer];
        UserProfile storage sellerProfile = userProfiles[agreement.seller];

        buyerProfile.agreementsCompleted += 1;
        sellerProfile.agreementsCompleted += 1;

        // Track total energy and value traded
        buyerProfile.totalEnergyTraded += agreement.finalEnergyAmount;
        sellerProfile.totalEnergyTraded += agreement.finalEnergyAmount;
        buyerProfile.totalValueTraded += agreement.finalTotalPrice;
        sellerProfile.totalValueTraded += agreement.finalTotalPrice;

        buyerProfile.lastActivityTimestamp = block.timestamp;
        sellerProfile.lastActivityTimestamp = block.timestamp;

        emit TradeCompleted(_agreementId);
        emit OfferUpdated(agreement.offerId, OfferStatus.COMPLETED);
    }

    /**
     * @dev Dispute and request refund for incomplete delivery
     * @param _agreementId ID of the agreement
     * @param _reason Reason for the refund request
     */
    function disputeAndRefund(
        bytes32 _agreementId,
        string calldata _reason
    ) external whenNotPaused nonReentrant onlyRole(MODERATOR_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement is not active");

        Offer storage offer = offers[agreement.offerId];

        // Process refund through escrow
        escrowContract.processRefund(agreement.escrowId);

        agreement.isActive = false;
        offer.status = OfferStatus.CANCELLED;

        emit TradeRefunded(_agreementId, _reason);
        emit OfferUpdated(agreement.offerId, OfferStatus.CANCELLED);
    }

    /**
     * @dev Get all active offers
     */
    function getActiveOffers()
        external
        view
        onlyRole(USER_ROLE)
        returns (bytes32[] memory)
    {
        return activeOfferIds;
    }

    /**
     * @dev Get offer details
     * @param _offerId The ID of the offer to get details for
     */
    function getOfferDetails(
        bytes32 _offerId
    )
        external
        view
        onlyRole(USER_ROLE)
        returns (
            bytes32 id,
            address creator,
            string memory creatorUsername,
            OfferType offerType,
            uint256 energyAmount,
            uint256 pricePerUnit,
            uint256 totalPrice,
            uint256 startTime,
            uint256 endTime,
            OfferStatus status,
            address counterparty,
            string memory counterpartyUsername,
            uint256 createdAt
        )
    {
        Offer storage offer = offers[_offerId];
        return (
            offer.id,
            offer.creator,
            offer.creatorUsername,
            offer.offerType,
            offer.energyAmount,
            offer.pricePerUnit,
            offer.totalPrice,
            offer.startTime,
            offer.endTime,
            offer.status,
            offer.counterparty,
            offer.counterpartyUsername,
            offer.createdAt
        );
    }

    /**
     * @dev Get all active counter offers for an offer
     * @param _offerId ID of the offer
     * @return addresses Array of addresses that have active counter offers
     * @return activeOffers Array of active counter offers
     */
    function getActiveCounterOffers(
        bytes32 _offerId
    )
        external
        view
        onlyRole(USER_ROLE)
        returns (address[] memory addresses, CounterOffer[] memory activeOffers)
    {
        address[] memory allCounterParties = offerCounterParties[_offerId];

        // First count active counter offers
        uint256 activeCount = 0;
        for (uint i = 0; i < allCounterParties.length; i++) {
            address counterParty = allCounterParties[i];
            CounterOffer[] storage counterOffers = counterOffersByAddress[
                _offerId
            ][counterParty];

            for (uint j = 0; j < counterOffers.length; j++) {
                if (counterOffers[j].isActive) {
                    activeCount++;
                    break;
                }
            }
        }

        // Create return arrays of the right size
        addresses = new address[](activeCount);
        activeOffers = new CounterOffer[](activeCount);

        // Fill return arrays
        uint256 index = 0;
        for (uint i = 0; i < allCounterParties.length; i++) {
            address counterParty = allCounterParties[i];
            CounterOffer[] storage counterOffers = counterOffersByAddress[
                _offerId
            ][counterParty];

            for (uint j = 0; j < counterOffers.length; j++) {
                if (counterOffers[j].isActive) {
                    addresses[index] = counterParty;
                    activeOffers[index] = counterOffers[j];
                    index++;
                    break;
                }
            }
        }

        return (addresses, activeOffers);
    }

    /**
     * @dev Get counter offer history for a specific user and offer
     * @param _offerId ID of the offer
     * @param _user Address of the user
     */
    function getUserCounterOfferHistory(
        bytes32 _offerId,
        address _user
    ) external view onlyRole(USER_ROLE) returns (CounterOffer[] memory) {
        return counterOffersByAddress[_offerId][_user];
    }

    /**
     * @dev Get offers created by a user
     * @param _user Address of the user
     * @return Array of offer IDs created by the user
     */
    function getUserOffers(
        address _user
    ) external view onlyRole(USER_ROLE) returns (bytes32[] memory) {
        return userOffers[_user];
    }

    /**
     * @dev Get agreements associated with a user
     * @param _user Address of the user
     * @return Array of agreement IDs associated with the user
     */
    function getUserAgreements(
        address _user
    ) external view onlyRole(USER_ROLE) returns (bytes32[] memory) {
        return userAgreements[_user];
    }

    /**
     * @dev Get agreements associated with a user by their username
     * @param _username Username of the user
     * @return Array of agreement IDs associated with the user
     */
    function getUserAgreementsByUsername(
        string calldata _username
    ) external view onlyRole(USER_ROLE) returns (bytes32[] memory) {
        address userAddress = usernameToAddress[_username];
        require(userAddress != address(0), "Username does not exist");

        return userAgreements[userAddress];
    }

    /**
     * @dev Get agreement details including usernames
     * @param _agreementId The ID of the agreement to get details for
     */
    function getAgreementDetails(
        bytes32 _agreementId
    )
        external
        view
        onlyRole(USER_ROLE)
        returns (
            bytes32 id,
            bytes32 offerId,
            address buyer,
            string memory buyerUsername,
            address seller,
            string memory sellerUsername,
            uint256 finalEnergyAmount,
            uint256 finalTotalPrice,
            uint256 agreedAt,
            bool isActive,
            bool funded
        )
    {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");

        return (
            agreement.id,
            agreement.offerId,
            agreement.buyer,
            agreement.buyerUsername,
            agreement.seller,
            agreement.sellerUsername,
            agreement.finalEnergyAmount,
            agreement.finalTotalPrice,
            agreement.agreedAt,
            agreement.isActive,
            agreement.funded
        );
    }

    /**
     * @dev Get user trading statistics
     * @param _user Address of the user
     */
    function getUserStats(
        address _user
    )
        external
        view
        returns (
            string memory username,
            uint256 offersCreated,
            uint256 offersCountered,
            uint256 agreementsCompleted,
            uint256 agreementsCancelled,
            uint256 disputesInitiated,
            uint256 disputesWon,
            uint256 totalEnergyTraded,
            uint256 totalValueTraded,
            uint256 lastActivityTimestamp
        )
    {
        UserProfile storage profile = userProfiles[_user];
        return (
            usernames[_user],
            profile.offersCreated,
            profile.offersCountered,
            profile.agreementsCompleted,
            profile.agreementsCancelled,
            profile.disputesInitiated,
            profile.disputesWon,
            profile.totalEnergyTraded,
            profile.totalValueTraded,
            profile.lastActivityTimestamp
        );
    }

    /**
     * @dev Get all counter parties for an offer
     * @param _offerId ID of the offer
     */
    function getOfferCounterParties(
        bytes32 _offerId
    ) external view returns (address[] memory) {
        return offerCounterParties[_offerId];
    }

    /**
     * @dev Add a function for buyers to dispute a milestone
     * @param _agreementId ID of the agreement
     * @param _percentage Percentage milestone to dispute
     * @param _reason Reason for the dispute
     */
    function disputeMilestone(
        bytes32 _agreementId,
        uint256 _percentage,
        string calldata _reason
    ) external whenNotPaused nonReentrant onlyRole(USER_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement is not active");
        require(msg.sender == agreement.buyer, "Only buyer can dispute");

        MilestoneCompletion storage milestone = agreement.milestones[
            _percentage
        ];
        require(milestone.timestamp > 0, "Milestone not reported yet");
        require(
            milestone.canDispute,
            "Milestone already finalized or disputed"
        );
        require(
            block.timestamp <= milestone.timestamp + DISPUTE_PERIOD,
            "Dispute period over"
        );

        milestone.disputed = true;
        milestone.canDispute = false;

        // Update user statistics
        userProfiles[msg.sender].disputesInitiated += 1;
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;

        emit MilestoneDisputed(_agreementId, _percentage, _reason);
    }

    /**
     * @dev Finalize a milestone after dispute period
     * @param _agreementId ID of the agreement
     * @param _percentage Percentage milestone to finalize
     */
    function finalizeMilestone(
        bytes32 _agreementId,
        uint256 _percentage
    ) external whenNotPaused nonReentrant {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");
        require(agreement.isActive, "Agreement is not active");

        MilestoneCompletion storage milestone = agreement.milestones[
            _percentage
        ];
        require(milestone.timestamp > 0, "Milestone not reported yet");
        require(milestone.canDispute, "Milestone already finalized");
        require(!milestone.disputed, "Milestone is disputed");
        require(
            block.timestamp > milestone.timestamp + DISPUTE_PERIOD,
            "Dispute period not over"
        );

        // Mark as no longer disputable
        milestone.canDispute = false;

        // If 100% finalized, complete the agreement
        if (_percentage == 100) {
            completeAgreement(_agreementId);
        }
    }

    /**
     * @dev Resolve a disputed milestone
     * @param _agreementId ID of the agreement
     * @param _percentage Percentage milestone under dispute
     * @param buyerWins Whether the buyer wins the dispute
     */
    function resolveDispute(
        bytes32 _agreementId,
        uint256 _percentage,
        bool buyerWins
    ) external onlyRole(ADMIN_ROLE) {
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.id == _agreementId, "Agreement does not exist");

        if (buyerWins) {
            escrowContract.processRefund(agreement.escrowId);
            agreement.isActive = false;
            // Update user statistics
            userProfiles[agreement.buyer].disputesWon += 1;
            emit TradeRefunded(_agreementId, "Admin resolved in buyer's favor");
        } else {
            escrowContract.releasePayment(agreement.escrowId, _percentage);
            emit EnergyDeliveryProgress(_agreementId, _percentage);
        }

        // Update activity timestamps
        userProfiles[agreement.buyer].lastActivityTimestamp = block.timestamp;
        userProfiles[agreement.seller].lastActivityTimestamp = block.timestamp;
    }

    /**
     * @dev Get a specific counter offer by its ID
     * @param _counterOfferId ID of the counter offer
     * @return id The unique ID of the counter offer
     * @return sender The address of the sender
     * @return senderUsername The username of the sender
     * @return timestamp The timestamp of the counter offer
     * @return proposedEnergyAmount The proposed energy amount in kWh
     * @return proposedPricePerUnit The proposed price per unit in tokens
     * @return proposedTotalPrice The proposed total price in tokens
     * @return isActive Whether the counter offer is active
     */
    function getCounterOfferById(
        bytes32 _counterOfferId
    )
        external
        view
        onlyRole(USER_ROLE)
        returns (
            bytes32 id,
            address sender,
            string memory senderUsername,
            uint256 timestamp,
            uint256 proposedEnergyAmount,
            uint256 proposedPricePerUnit,
            uint256 proposedTotalPrice,
            bool isActive
        )
    {
        CounterOffer memory counterOffer = counterOffersById[_counterOfferId];
        require(
            counterOffer.id == _counterOfferId,
            "Counter offer does not exist"
        );

        return (
            counterOffer.id,
            counterOffer.sender,
            counterOffer.senderUsername,
            counterOffer.timestamp,
            counterOffer.proposedEnergyAmount,
            counterOffer.proposedPricePerUnit,
            counterOffer.proposedTotalPrice,
            counterOffer.isActive
        );
    }

    // ============= Admin functions =============

    /**
     * @dev Pause the contract
     * Only callable by admin
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * Only callable by admin
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Set a new escrow contract
     * @param _newEscrowContract Address of the new escrow contract
     * Only callable by owner
     */
    function setEscrowContract(address _newEscrowContract) external onlyOwner {
        require(
            _newEscrowContract != address(0),
            "Invalid escrow contract address"
        );
        escrowContract = EnergyEscrow(_newEscrowContract);
    }

    /**
     * @dev Grant moderator role to an address
     * @param _account Address to grant the role to
     */
    function addModerator(address _account) external onlyRole(ADMIN_ROLE) {
        grantRole(MODERATOR_ROLE, _account);
    }

    /**
     * @dev Grant admin role to an address
     * @param _account Address to grant the role to
     */
    function addAdmin(address _account) external onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, _account);
    }

    /**
     * @dev Grant user role to an address and optionally set username
     * @param _account Address to grant the role to
     * @param _username Optional username to set for the user (empty string to skip)
     */
    function addUser(
        address _account,
        string calldata _username
    ) external onlyRole(ADMIN_ROLE) {
        grantRole(USER_ROLE, _account);

        // If a username is provided, register it for the user
        if (bytes(_username).length > 0) {
            require(
                bytes(_username).length <= MAX_USERNAME_LENGTH,
                "Username too long"
            );
            require(
                usernameToAddress[_username] == address(0),
                "Username already taken"
            );

            usernames[_account] = _username;
            usernameToAddress[_username] = _account;

            // Initialize user profile
            userProfiles[_account] = UserProfile({
                offersCreated: 0,
                offersCountered: 0,
                agreementsCompleted: 0,
                agreementsCancelled: 0,
                disputesInitiated: 0,
                disputesWon: 0,
                totalEnergyTraded: 0,
                totalValueTraded: 0,
                lastActivityTimestamp: block.timestamp
            });

            emit UsernameRegistered(_account, _username);
        }
    }

    /**
     * @dev Revoke moderator role from an address
     * @param _account Address to revoke the role from
     */
    function removeModerator(address _account) external onlyRole(ADMIN_ROLE) {
        revokeRole(MODERATOR_ROLE, _account);
    }

    /**
     * @dev Cancel an offer (for moderation purposes)
     * @param _offerId ID of the offer to cancel
     * Only callable by moderators or admins
     */
    function moderateOffer(bytes32 _offerId) external onlyRole(MODERATOR_ROLE) {
        Offer storage offer = offers[_offerId];
        require(offer.id == _offerId, "Offer does not exist");
        require(
            offer.status == OfferStatus.ACTIVE ||
                offer.status == OfferStatus.COUNTERED,
            "Offer cannot be moderated"
        );

        offer.status = OfferStatus.CANCELLED;

        // Remove from active offers if needed
        if (
            activeOfferIndexes[_offerId] > 0 ||
            (activeOfferIds.length > 0 && activeOfferIds[0] == _offerId)
        ) {
            _removeFromActiveOffers(_offerId);
        }

        emit OfferUpdated(_offerId, OfferStatus.CANCELLED);
    }

    /**
     * @dev Set the price tracker contract address
     * @param _days Number of days to fetch historical data for
     */
    function getHistoricalPriceData(
        uint256 _days
    )
        external
        view
        returns (
            uint256[] memory timestamps,
            uint256[] memory prices,
            uint256[] memory volumes
        )
    {
        return priceTracker.getHistoricalPriceData(_days);
    }

    /**
     * @dev Get the weighted average price of energy in the last 7 days
     * @return Average price per kWh
     */
    function getAveragePriceLastWeek() external view returns (uint256) {
        return priceTracker.getAveragePriceLastWeek();
    }

    /**
     * @dev Set a new price tracker contract
     * @param _newPriceTracker Address of the new price tracker contract
     */
    function setPriceTracker(address _newPriceTracker) external onlyOwner {
        require(_newPriceTracker != address(0), "Invalid price tracker");
        priceTracker = PriceTracker(_newPriceTracker);
    }
}
