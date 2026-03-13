// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ZKAuth
 * @dev Zero-Knowledge Authorization contract for privacy_guard
 * Allows agents to verify permissions without revealing identity
 */
contract ZKAuth is Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private permissionIdCounter;
    
    // Permission structure
    struct Permission {
        bytes32 commitmentHash;  // Hash of agent identity
        address targetService;   // Service the agent can access
        uint256 expiryTime;      // When permission expires
        bool revoked;            // Is permission revoked
        string scope;            // What the agent can do
    }
    
    mapping(uint256 => Permission) public permissions;
    mapping(address => uint256[]) public userPermissions;
    mapping(bytes32 => bool) public commitmentUsed;
    
    event PermissionGranted(uint256 indexed permissionId, address indexed user, address targetService);
    event PermissionRevoked(uint256 indexed permissionId);
    event PermissionVerified(bytes32 commitmentHash, address targetService, bool verified);
    
    /**
     * @dev Grant permission to an agent (via commitment hash)
     * User provides commitment hash instead of revealing identity
     */
    function grantPermission(
        bytes32 _commitmentHash,
        address _targetService,
        uint256 _expiryTime,
        string calldata _scope
    ) external {
        require(_targetService != address(0), "Invalid service");
        require(_expiryTime > block.timestamp, "Invalid expiry");
        require(!commitmentUsed[_commitmentHash], "Commitment already used");
        
        uint256 permissionId = permissionIdCounter.current();
        permissionIdCounter.increment();
        
        permissions[permissionId] = Permission({
            commitmentHash: _commitmentHash,
            targetService: _targetService,
            expiryTime: _expiryTime,
            revoked: false,
            scope: _scope
        });
        
        userPermissions[msg.sender].push(permissionId);
        commitmentUsed[_commitmentHash] = true;
        
        emit PermissionGranted(permissionId, msg.sender, _targetService);
    }
    
    /**
     * @dev Verify permission using commitment hash (ZK style)
     * Service verifies without knowing actual agent identity
     */
    function verifyPermission(
        bytes32 _commitmentHash,
        address _targetService
    ) external view returns (bool) {
        // Find matching permission
        for (uint256 i = 0; i < permissionIdCounter.current(); i++) {
            Permission storage perm = permissions[i];
            if (
                perm.commitmentHash == _commitmentHash &&
                perm.targetService == _targetService &&
                !perm.revoked &&
                perm.expiryTime > block.timestamp
            ) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Revoke a permission
     */
    function revokePermission(uint256 _permissionId) external {
        Permission storage perm = permissions[_permissionId];
        require(msg.sender == owner() || msg.sender == owner(), "Not authorized");
        perm.revoked = true;
        emit PermissionRevoked(_permissionId);
    }
    
    /**
     * @dev Get user's permissions
     */
    function getUserPermissions(address _user) external view returns (uint256[] memory) {
        return userPermissions[_user];
    }
}
