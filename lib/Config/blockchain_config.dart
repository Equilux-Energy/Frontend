class BlockchainConfig {
  // Contract addresses
  static const String tokenContractAddress = '0xYourTokenContractAddress';
  static const String marketContractAddress = '0xYourMarketContractAddress';
  
  // Supported networks
  static const Map<String, int> networks = {
    'Ethereum Mainnet': 1,
    'Goerli Testnet': 5,
    'Sepolia Testnet': 11155111,
    'Polygon Mainnet': 137,
    'Mumbai Testnet': 80001,
    'Holesky Testnet': 170000,
  };
  
  // RPC URLs for different networks (used as fallbacks)
  static const Map<int, String> rpcUrls = {
    1: 'https://ethereum.publicnode.com',
    5: 'https://goerli.infura.io/v3/YOUR_INFURA_KEY',
    11155111: 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY',
    137: 'https://polygon-rpc.com',
    80001: 'https://rpc-mumbai.maticvigil.com',
    170000: 'https://holesky.infura.io/v3/5f3a85c71fb04fa6ae7f7d2494f3b036',
  };
}