# 🎰 Cyfrin Lottery - Decentralized Raffle Contract

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.19-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-red)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📖 Overview

The **Cyfrin Lottery** is a decentralized, provably fair raffle system built on Ethereum. It allows users to participate in automated lottery draws where winners are selected using Chainlink VRF (Verifiable Random Function) for true randomness. The contract is fully automated using Chainlink Keepers for regular draw execution.

### 🎯 Key Features

- **Provably Fair**: Uses Chainlink VRF v2.5 for cryptographically secure random number generation
- **Fully Automated**: Chainlink Keepers automatically trigger lottery draws based on predefined conditions
- **Transparent**: All transactions and winner selections are recorded on-chain
- **Gas Optimized**: Efficient Solidity code with minimal gas consumption
- **Secure**: Comprehensive error handling and security measures

## 🏗️ Architecture & Mechanisms

### Core Components

#### 1. **Raffle State Management**
The contract operates in two distinct states:
- `OPEN`: Players can enter the raffle
- `CALCULATING`: Winner selection in progress (no new entries allowed)

#### 2. **Entry System**
- Players pay a fixed entrance fee to join the raffle
- All participants are stored in a dynamic array
- Each entry increases the total prize pool

#### 3. **Automated Draw System**
The lottery automatically executes when ALL conditions are met:
- ✅ Sufficient time has passed since last draw
- ✅ Raffle is in OPEN state
- ✅ Contract has ETH balance
- ✅ At least one player has entered

#### 4. **Random Winner Selection**
- Utilizes Chainlink VRF v2.5 for tamper-proof randomness
- Winner index: `randomNumber % totalPlayers`
- Immediate prize distribution upon selection

### 🔧 Technical Mechanisms

#### **Chainlink VRF Integration**
```solidity
// Request random words from Chainlink VRF
VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
    keyHash: i_keyHash,
    subId: i_subscriptionId,
    requestConfirmations: REQUEST_CONFIRMATIONS,
    callbackGasLimit: i_callbackGasLimit,
    numWords: NUM_WORDS,
    extraArgs: VRFV2PlusClient._argsToBytes(
        VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
    )
});
```

#### **Chainlink Keepers Automation**
The `checkUpkeep` function is monitored by Chainlink Keepers:
```solidity
function checkUpkeep(bytes memory) public view returns (bool upkeepNeeded, bytes memory) {
    bool isOpen = RaffleState.OPEN == s_raffleState;
    bool timePassed = ((block.timestamp - s_LastTimestamp) > i_interval);
    bool hasPlayers = s_players.length > 0;
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
}
```

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- [Node.js](https://nodejs.org/) (v16+)
- [Git](https://git-scm.com/)

### Installation

```bash
git clone https://github.com/your-username/cyfrin-lottery
cd cyfrin-lottery
forge install
```

### Deployment Setup

1. **Environment Variables**
   Create a `.env` file:
   ```env
   PRIVATE_KEY=your_private_key_here
   SEPOLIA_RPC_URL=your_sepolia_rpc_url
   ETHERSCAN_API_KEY=your_etherscan_api_key
   ```

2. **Deploy to Sepolia Testnet**
   ```bash
   make deploy ARGS="--network sepolia"
   ```

## 🧪 Testing

### Run Test Suite
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testFulfillRandomNumbersEndToEnd

# Check test coverage
forge coverage
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: Full workflow testing
- **Fuzz Tests**: Random input testing

## 🎮 How to Use

### For Players

1. **Enter the Raffle**
   ```solidity
   raffle.enterRaffle{value: entranceFee}();
   ```

2. **Check Current State**
   ```solidity
   RaffleState state = raffle.getRaffleState();
   uint256 entranceFee = raffle.getEntranceFee();
   ```

### For Developers

1. **Deploy Contract**
   ```bash
   forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
   ```

2. **Verify Contract**
   ```bash
   forge verify-contract <CONTRACT_ADDRESS> src/raffle.sol:Raffle --etherscan-api-key $ETHERSCAN_API_KEY
   ```

## 📋 Contract Functions

### Public Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `enterRaffle()` | Enter the raffle by paying entrance fee | None (payable) | None |
| `checkUpkeep()` | Check if upkeep is needed | `bytes checkData` | `bool upkeepNeeded, bytes performData` |
| `performUpkeep()` | Trigger raffle draw | `bytes performData` | None |

### View Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `getEntranceFee()` | Get required entrance fee | `uint256` |
| `getRaffleState()` | Get current raffle state | `RaffleState` |
| `getPlayer(uint256)` | Get player address by index | `address` |
| `getRecentWinner()` | Get last winner address | `address` |
| `getLastTimestamp()` | Get last draw timestamp | `uint256` |

## ⚡ Pro Tips

### For Users
- **Entry Timing**: Enter early in the round for maximum participation time
- **Gas Optimization**: Enter during low network congestion periods
- **Multiple Entries**: Each transaction counts as one entry (consider gas costs)

### For Developers
- **VRF Subscription**: Ensure sufficient LINK tokens in your VRF subscription
- **Gas Limits**: Set appropriate callback gas limits for your network
- **Testing**: Always test on testnets before mainnet deployment
- **Monitoring**: Set up monitoring for contract events and state changes

### Security Considerations
- **Reentrancy**: Contract uses checks-effects-interactions pattern
- **Random Number Attack**: Chainlink VRF prevents manipulation
- **State Validation**: All state changes are properly validated
- **Access Control**: No admin functions reduce centralization risks

## 🔍 Contract Verification

After deployment, verify your contract on Etherscan:

```bash
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 200 \
  --watch \
  --constructor-args $(cast abi-encode "constructor(uint256,uint256,address,bytes32,uint256,uint32)" 30 10000000000000000 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae 12345 500000) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  0xYourContractAddress \
  src/raffle.sol:Raffle
```

## 📊 Gas Estimates

| Function | Gas Estimate | Description |
|----------|-------------|-------------|
| `enterRaffle()` | ~47,000 | Entry with event emission |
| `performUpkeep()` | ~144,000 | VRF request initiation |
| `fulfillRandomWords()` | ~73,000 | Winner selection & transfer |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Chainlink VRF Documentation](https://docs.chain.link/vrf/v2/introduction)
- [Chainlink Keepers Documentation](https://docs.chain.link/chainlink-automation/introduction)
- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## ⚠️ Disclaimer

This smart contract is provided as-is for educational and development purposes. Users should conduct their own security audits before deploying to mainnet or handling significant value. The developers are not responsible for any financial losses incurred through the use of this contract.

---

**Built with ❤️ by [0xSTN](https://github.com/your-github) | Powered by Chainlink & Foundry** 