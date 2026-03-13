const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ZKAuth - Zero-Knowledge Authorization", function () {
  let zkAuth;
  let owner, user1, user2, service1, service2;

  beforeEach(async function () {
    const ZKAuth = await ethers.getContractFactory("ZKAuth");
    zkAuth = await ZKAuth.deploy();
    
    [owner, user1, user2, service1, service2] = await ethers.getSigners();
  });

  describe("Permission Management", function () {
    it("Should grant permission with commitment hash", async function () {
      const commitmentHash = ethers.keccak256(ethers.toUtf8Bytes("user1_identity"));
      const expiryTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
      
      await expect(
        zkAuth.connect(user1).grantPermission(
          commitmentHash,
          service1.address,
          expiryTime,
          "read_profile"
        )
      ).to.emit(zkAuth, "PermissionGranted");

      const permissions = await zkAuth.getUserPermissions(user1.address);
      expect(permissions.length).to.equal(1);
    });

    it("Should verify permission without revealing identity", async function () {
      const commitmentHash = ethers.keccak256(ethers.toUtf8Bytes("secret_user"));
      const expiryTime = Math.floor(Date.now() / 1000) + 3600;
      
      await zkAuth.connect(user1).grantPermission(
        commitmentHash,
        service1.address,
        expiryTime,
        "access"
      );

      const isVerified = await zkAuth.verifyPermission(commitmentHash, service1.address);
      expect(isVerified).to.be.true;
    });

    it("Should reject invalid service address", async function () {
      const commitmentHash = ethers.keccak256(ethers.toUtf8Bytes("test"));
      const expiryTime = Math.floor(Date.now() / 1000) + 3600;
      
      await expect(
        zkAuth.connect(user1).grantPermission(
          commitmentHash,
          ethers.ZeroAddress,
          expiryTime,
          "access"
        )
      ).to.be.revertedWith("Invalid service");
    });

    it("Should prevent duplicate commitments", async function () {
      const commitmentHash = ethers.keccak256(ethers.toUtf8Bytes("unique"));
      const expiryTime = Math.floor(Date.now() / 1000) + 3600;
      
      await zkAuth.connect(user1).grantPermission(
        commitmentHash,
        service1.address,
        expiryTime,
        "access"
      );

      await expect(
        zkAuth.connect(user2).grantPermission(
          commitmentHash,
          service2.address,
          expiryTime,
          "access"
        )
      ).to.be.revertedWith("Commitment already used");
    });
  });

  describe("Permission Revocation", function () {
    it("Should revoke a permission", async function () {
      const commitmentHash = ethers.keccak256(ethers.toUtf8Bytes("revoke_test"));
      const expiryTime = Math.floor(Date.now() / 1000) + 3600;
      
      await zkAuth.connect(user1).grantPermission(
        commitmentHash,
        service1.address,
        expiryTime,
        "access"
      );

      const isVerifiedBefore = await zkAuth.verifyPermission(commitmentHash, service1.address);
      expect(isVerifiedBefore).to.be.true;

      await zkAuth.connect(owner).revokePermission(0);

      const isVerifiedAfter = await zkAuth.verifyPermission(commitmentHash, service1.address);
      expect(isVerifiedAfter).to.be.false;
    });
  });

  describe("Permission Expiry", function () {
    it("Should not verify expired permission", async function () {
      const commitmentHash = ethers.keccak256(ethers.toUtf8Bytes("expired"));
      const expiryTime = Math.floor(Date.now() / 1000) + 1; // 1 second from now
      
      await zkAuth.connect(user1).grantPermission(
        commitmentHash,
        service1.address,
        expiryTime,
        "access"
      );

      // Wait for expiry
      await new Promise(resolve => setTimeout(resolve, 2000));

      const isVerified = await zkAuth.verifyPermission(commitmentHash, service1.address);
      expect(isVerified).to.be.false;
    });
  });
});
