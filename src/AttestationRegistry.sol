// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Attestation, AttestationPayload, Portal } from "./types/Structs.sol";
import { PortalRegistry } from "./PortalRegistry.sol";
import { SchemaRegistry } from "./SchemaRegistry.sol";
import { IRouter } from "./interface/IRouter.sol";

/**
 * @title Attestation Registry
 * @author Consensys
 * @notice This contract stores a registry of all attestations
 */
contract AttestationRegistry is OwnableUpgradeable {
  IRouter public router;

  uint16 private version;
  uint private attestationIdCounter;
  mapping(bytes32 attestationId => Attestation attestation) private attestations;

  mapping(bytes32 attestationId => Attestation attestation) private attestations;

  /// @notice Error thrown when a non-portal tries to call a method that can only be called by a portal
  error OnlyPortal();
  /// @notice Error thrown when an invalid Router address is given
  error RouterInvalid();
  /// @notice Error thrown when an attestation is not registered in the AttestationRegistry
  error AttestationNotAttested();
  /// @notice Error thrown when an attempt is made to revoke an attestation by an entity other than the attesting portal
  error OnlyAttestingPortal();
  /// @notice Error thrown when an attempt is made to revoke an attestation by someone else than the orignal attester
  error OnlyAttester();
  /// @notice Error thrown when an attempt is made to revoke an attestation that was already revoked
  error AlreadyRevoked();
  /// @notice Error thrown when an attempt is made to revoke an attestation based on a non-revocable schema
  error AttestationNotRevocable();

  /// @notice Event emitted when an attestation is registered
  event AttestationRegistered(Attestation attestation);
  /// @notice Event emitted when an attestation is revoked
  event AttestationRevoked(bytes32 attestationId, bytes32 replacedBy);
  /// @notice Event emitted when the version number is incremented
  event VersionUpdated(uint16 version);

  /**
   * @notice Checks if the caller is a registered portal
   * @param portal the portal address
   */
  modifier onlyPortals(address portal) {
    bool isPortalRegistered = PortalRegistry(router.getPortalRegistry()).isRegistered(portal);
    if (!isPortalRegistered) revert OnlyPortal();
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Contract initialization
   */
  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @notice Changes the address for the Router
   */
  function updateRouter(address _router) public onlyOwner {
    if (_router == address(0)) revert RouterInvalid();
    router = IRouter(_router);
  }

  /**
   * @notice Registers an attestation to the AttestationRegistry
   * @param attestationPayload the attestation payload to create attestation and register it
   * @dev This method is only callable by a registered Portal
   */
  function attest(AttestationPayload calldata attestationPayload, address attester) external onlyPortals(msg.sender) {
    // Auto increment attestation counter
    attestationIdCounter++;
    // Create attestation
    Attestation memory attestation = Attestation(
      bytes32(keccak256(abi.encode((attestationIdCounter)))),
      attestationPayload.schemaId,
      attester,
      msg.sender,
      attestationPayload.subject,
      block.timestamp,
      attestationPayload.expirationDate,
      false,
      0,
      bytes32(0),
      version,
      attestationPayload.attestationData
    );
    attestations[attestation.attestationId] = attestation;
    emit AttestationRegistered(attestation);
  }

  /**
   * @notice Revokes an attestation for given identifier and can replace it by an other one
   * @param attestationId the attestation ID to revoke
   * @param replacedBy the replacing attestation ID (leave empty to just revoke)
   */
  function revoke(bytes32 attestationId, bytes32 replacedBy) external {
    if (!isRegistered(attestationId)) revert AttestationNotAttested();
    if (attestations[attestationId].revoked) revert AlreadyRevoked();
    if (msg.sender != attestations[attestationId].portal) revert OnlyAttestingPortal();
    if (tx.origin != attestations[attestationId].attester) revert OnlyAttester();
    if (!isRevocable(attestations[attestationId].portal)) revert AttestationNotRevocable();

    attestations[attestationId].revoked = true;
    attestations[attestationId].revocationDate = block.timestamp;

    if (isRegistered(replacedBy)) attestations[attestationId].replacedBy = replacedBy;

    emit AttestationRevoked(attestationId, replacedBy);
  }

  /**
   * @notice Checks if an attestation is registered
   * @param attestationId the attestation identifier
   * @return true if the attestation is registered, false otherwise
   */
  function isRegistered(bytes32 attestationId) public view returns (bool) {
    return attestations[attestationId].attestationId != bytes32(0);
  }

  /**
   * @notice Checks whether a portal issues revocable attestations
   * @param portalId the portal address (ID)
   * @return true if the attestations issued by this portal are revocable, false otherwise
   */
  function isRevocable(address portalId) public view returns (bool) {
    PortalRegistry portalRegistry = PortalRegistry(router.getPortalRegistry());
    return portalRegistry.getPortalByAddress(portalId).isRevocable;
  }

  /**
   * @notice Gets an attestation by its identifier
   * @param attestationId the attestation identifier
   * @return the attestation
   */
  function getAttestation(bytes32 attestationId) public view returns (Attestation memory) {
    if (!isRegistered(attestationId)) revert AttestationNotAttested();
    return attestations[attestationId];
  }

  /**
   * @notice Increments the registry version
   * @return The new version number
   */
  function incrementVersionNumber() public onlyOwner returns (uint16) {
    ++version;
    emit VersionUpdated(version);
    return version;
  }

  /**
   * @notice Gets the registry version
   * @return The current version number
   */
  function getVersionNumber() public view returns (uint16) {
    return version;
  }

  /**
   * @notice Gets the attestation id counter
   * @return The attestationIdCounter
   */
  function getAttestationIdCounter() public view returns (uint) {
    return attestationIdCounter;
  }
}
