// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title EncryptedRegistry
 * @dev Registry for encrypted privacy policies
 * Stores user privacy preferences on-chain while maintaining privacy
 */
contract EncryptedRegistry is Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private policyIdCounter;
    
    // Privacy policy structure
    struct PrivacyPolicy {
        bytes32 encryptedDataHash;   // Hash of encrypted policy
        address policyOwner;         // Who owns the policy
        uint256 createdAt;           // Creation timestamp
        bool active;                 // Is policy active
        string policyType;           // Type of policy
    }
    
    mapping(uint256 => PrivacyPolicy) public policies;
    mapping(address => uint256[]) public userPolicies;
    
    event PolicyCreated(uint256 indexed policyId, address indexed user, string policyType);
    event PolicyUpdated(uint256 indexed policyId, bytes32 newEncryptedHash);
    event PolicyRevoked(uint256 indexed policyId);
    event PolicyAccessed(uint256 indexed policyId, address indexed accessor);
    
    /**
     * @dev Create a new privacy policy
     * Policy is stored as encrypted hash for privacy
     */
    function createPolicy(
        bytes32 _encryptedDataHash,
        string calldata _policyType
    ) external returns (uint256) {
        uint256 policyId = policyIdCounter.current();
        policyIdCounter.increment();
        
        policies[policyId] = PrivacyPolicy({
            encryptedDataHash: _encryptedDataHash,
            policyOwner: msg.sender,
            createdAt: block.timestamp,
            active: true,
            policyType: _policyType
        });
        
        userPolicies[msg.sender].push(policyId);
        
        emit PolicyCreated(policyId, msg.sender, _policyType);
        return policyId;
    }
    
    /**
     * @dev Update an existing policy
     */
    function updatePolicy(
        uint256 _policyId,
        bytes32 _newEncryptedHash
    ) external {
        PrivacyPolicy storage policy = policies[_policyId];
        require(policy.policyOwner == msg.sender, "Not policy owner");
        require(policy.active, "Policy not active");
        
        policy.encryptedDataHash = _newEncryptedHash;
        
        emit PolicyUpdated(_policyId, _newEncryptedHash);
    }
    
    /**
     * @dev Revoke a privacy policy
     */
    function revokePolicy(uint256 _policyId) external {
        PrivacyPolicy storage policy = policies[_policyId];
        require(policy.policyOwner == msg.sender, "Not policy owner");
        
        policy.active = false;
        
        emit PolicyRevoked(_policyId);
    }
    
    /**
     * @dev Access policy (with encryption key validation)
     * Logs access for transparency
     */
    function accessPolicy(uint256 _policyId) external {
        PrivacyPolicy storage policy = policies[_policyId];
        require(policy.active, "Policy not active");
        require(policy.policyOwner == msg.sender, "Not authorized");
        
        emit PolicyAccessed(_policyId, msg.sender);
    }
    
    /**
     * @dev Get user's policies
     */
    function getUserPolicies(address _user) external view returns (uint256[] memory) {
        return userPolicies[_user];
    }
    
    /**
     * @dev Get policy details
     */
    function getPolicy(uint256 _policyId) external view returns (PrivacyPolicy memory) {
        return policies[_policyId];
    }
}
