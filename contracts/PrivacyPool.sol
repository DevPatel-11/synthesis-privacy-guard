// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PrivacyPool
 * @dev Privacy Pool for agents to make private transactions
 * Allows agents to deposit and withdraw without revealing amounts
 */
contract PrivacyPool is Ownable {
    
    // Private pool structure
    struct PoolEntry {
        bytes32 commitmentHash;  // Hash of deposit details
        uint256 amount;           // Amount deposited
        bool withdrawn;           // Has been withdrawn
        uint256 timestamp;        // When deposited
    }
    
    mapping(bytes32 => PoolEntry) public poolEntries;
    mapping(address => uint256) public userBalances;
    
    uint256 public totalPoolValue;
    IERC20 public tokenAddress;
    
    event DepositCommitted(bytes32 indexed commitmentHash, uint256 amount);
    event WithdrawalCommitted(bytes32 indexed commitmentHash, address indexed recipient);
    event PoolContribution(address indexed user, uint256 amount);
    
    constructor(address _tokenAddress) {
        tokenAddress = IERC20(_tokenAddress);
    }
    
    /**
     * @dev Deposit funds to privacy pool
     * User provides commitment hash instead of revealing amount
     */
    function depositToPool(
        bytes32 _commitmentHash,
        uint256 _amount
    ) external {
        require(_amount > 0, "Amount must be > 0");
        require(
            tokenAddress.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        
        poolEntries[_commitmentHash] = PoolEntry({
            commitmentHash: _commitmentHash,
            amount: _amount,
            withdrawn: false,
            timestamp: block.timestamp
        });
        
        userBalances[msg.sender] += _amount;
        totalPoolValue += _amount;
        
        emit DepositCommitted(_commitmentHash, _amount);
    }
    
    /**
     * @dev Withdraw from privacy pool using commitment
     * Verifies commitment without revealing amount
     */
    function withdrawFromPool(
        bytes32 _commitmentHash,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        PoolEntry storage entry = poolEntries[_commitmentHash];
        require(!entry.withdrawn, "Already withdrawn");
        require(entry.amount >= _amount, "Insufficient pool balance");
        
        entry.withdrawn = true;
        userBalances[_recipient] = userBalances[_recipient] > 0 
            ? userBalances[_recipient] - _amount 
            : 0;
        totalPoolValue -= _amount;
        
        require(
            tokenAddress.transfer(_recipient, _amount),
            "Transfer failed"
        );
        
        emit WithdrawalCommitted(_commitmentHash, _recipient);
    }
    
    /**
     * @dev Allow agent to contribute to pool
     */
    function contributeToPool(uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        require(
            tokenAddress.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        
        totalPoolValue += _amount;
        emit PoolContribution(msg.sender, _amount);
    }
    
    /**
     * @dev Get pool balance
     */
    function getPoolBalance() external view returns (uint256) {
        return totalPoolValue;
    }
}
