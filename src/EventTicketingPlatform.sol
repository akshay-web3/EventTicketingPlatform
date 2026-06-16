// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EventTicketingPlatform {
    enum EventType {
        None,
        Conference,
        Workshop,
        Hackathon,
        Meetup,
        Webinar,
        Summit
    }

    enum TicketTier {
        Standard,
        Premium,
        VIP
    }

    struct Ticket {
        uint256 ticketId;
        address buyer;
        string eventName;
        uint256 purchaseAmount;
        uint256 purchaseTimestamp;
        uint256 eventTimestamp;
        EventType eventType;
        TicketTier ticketTier;
    }

    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => bool) public ticketUsed;

    uint256 public totalTicketSold;

    address public owner;

    event TicketPurchased(
        uint256 indexed ticketId,
        address indexed buyer,
        string eventName,
        uint256 amountPaid,
        EventType eventType
    );

    error EventTicketingPlatform__NotOwner();
    error EventTicketingPlatform__InvalidAmount();
    error EventTicketingPlatform__InvalidEventType();
    error EventTicketingPlatform__EventDateShouldBeFutureDate();
    error EventTicketingPlatform__TicketIdAlreadyExists();
    error EventTicketingPlatform__TicketIdDoesNotExist();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert EventTicketingPlatform__NotOwner();
        }
        _;
    }

    modifier checkTicketExists(uint256 _ticketId) {
        if (!ticketUsed[_ticketId]) {
            revert EventTicketingPlatform__TicketIdDoesNotExist();
        }
        _;
    }

    function purchaseTicket(
        uint256 _ticketId,
        string memory _eventName,
        uint256 _eventTimestamp,
        EventType _eventType,
        TicketTier _ticketTier
    ) external payable {
        if (msg.value == 0) {
            revert EventTicketingPlatform__InvalidAmount();
        }

        if (_eventType == EventType.None) {
            revert EventTicketingPlatform__InvalidEventType();
        }

        if (_eventTimestamp <= block.timestamp) {
            revert EventTicketingPlatform__EventDateShouldBeFutureDate();
        }

        if (ticketUsed[_ticketId]) {
            revert EventTicketingPlatform__TicketIdAlreadyExists();
        }

        Ticket memory ticket = Ticket({
            ticketId: _ticketId,
            buyer: msg.sender,
            eventName: _eventName,
            purchaseAmount: msg.value,
            purchaseTimestamp: block.timestamp,
            eventTimestamp: _eventTimestamp,
            eventType: _eventType,
            ticketTier: _ticketTier
        });

        tickets[_ticketId] = ticket;

        ticketUsed[_ticketId] = true;
        totalTicketSold++;

            emit TicketPurchased(
            _ticketId,
            msg.sender,
            _eventName,
            msg.value,
            _eventType
        );
    }

    function getDaysUntilEvent(
        uint256 _ticketId
    ) public view checkTicketExists(_ticketId) returns (uint256 daysRemaining) {
        return (tickets[_ticketId].eventTimestamp - block.timestamp) / 1 days;
    }

    function calculateRefundAmount(
        uint256 _ticketId
    ) public view checkTicketExists(_ticketId) returns (uint256 refundAmount) {
        uint256 daysRemaining = getDaysUntilEvent(_ticketId);

        if (daysRemaining >= 30) {
            refundAmount = (tickets[_ticketId].purchaseAmount * 80) / 100;
        } else if (daysRemaining >= 15) {
            refundAmount = (tickets[_ticketId].purchaseAmount * 50) / 100;
        } else if (daysRemaining >= 7) {
            refundAmount = (tickets[_ticketId].purchaseAmount * 25) / 100;
        } else {
            refundAmount = 0;
        }
    }

    function getTicketSummary(
        uint256 _ticketId
    )
        external
        view
        checkTicketExists(_ticketId)
        returns (address buyer, uint256 purchaseAmount, TicketTier tier)
    {
        Ticket storage ticket = tickets[_ticketId];

        return (
            ticket.buyer,
            ticket.purchaseAmount,
            ticket.ticketTier
        );
    }
}
