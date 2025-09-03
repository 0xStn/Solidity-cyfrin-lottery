//SPDX-License-Identifier: MIT
// subscription ID : 22560620148906485815467602214408237484566378994492981189688539673169208381502
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.19;

/**
 * @title Raffle contract
 * @author 0xSTN
 * @notice This contract is for creating a sample raffle
 * @dev A simple raffle contract using Chainlink VRF 2.5
 */
import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // errors
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotMet(
        uint256 balance,
        uint256 playerLength,
        uint256 raffleState
    );

    // type declaration
    enum RaffleState {
        OPEN, // 0
        CALCULATING //1
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address payable[] private s_players;
    uint256 private s_LastTimestamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit;

    event RaffleEntered(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 interval,
        uint256 entranceFee,
        address vrfCoordinator,
        bytes32 gaslane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_LastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;

        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gaslane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    // make a raffle pool to enter the participants
    function enterRaffle() public payable {
        // like we say if the raffle flag not open then revert it too
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // require msg.value > i_entranceFee
        /*but it costs more gas , we can use custom error with revert
         but we use old version so its not supported in this project */

        // require(msg.value >= i_entranceFee , "Not enough Eth to enter raffle !");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_LastTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        // if all conditions true
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    // pick a winner from a pool
    // pick a random number (winner)
    // automate it
    // pick a random winner
    function performUpkeep(bytes calldata /* performData */) external {
        // we check if upkeepNeeded is true or not
        // def bool data and check if it true or not
        (bool upkeepNeeded, ) = checkUpkeep("0x0");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotMet(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // turn raffle flag to be in calculating winner state
        s_raffleState = RaffleState.CALCULATING;

        // from VRF contract this code will make a request to the VRF coordinator
        // request RNG
        // select RNG
        // Will revert if subscription is not set and funded.

        VRFV2PlusClient.RandomWordsRequest memory request;

        request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    // for vrfconsumer
    function fulfillRandomWords(
        uint256,
        /*requestId*/ uint256[] calldata _randomWords
    ) internal override {
        uint256 IndexOfWinner = _randomWords[0] % s_players.length;
        address payable recentWinner = s_players[IndexOfWinner];
        s_recentWinner = recentWinner;
        /*we now open the raffle after pick the winner
        resetting the players array
        s_players = new address payable[](0);  //can be also
        // resetting the time interval */
        delete s_players;
        s_LastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        emit PickedWinner(recentWinner);

        // give winner contract eth
        (bool success, ) = recentWinner.call{value: address(this).balance}(
            "Winner Winner chicken dinner!"
        );
        if (!success) {
            revert Raffle__TransferFailed();
        }
        // we now open the raffle after pick the winner
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 IndexOfPlayer) external view returns (address) {
        return s_players[IndexOfPlayer];
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_LastTimestamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
