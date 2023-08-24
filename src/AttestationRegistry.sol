// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Attestation } from "./types/Structs.sol";
import { PortalRegistry } from "./PortalRegistry.sol";
import { SchemaRegistry } from "./SchemaRegistry.sol";

/**
 * @title Attestation Registry
 * @author Consensys
 * @notice This contract stores a registry of all attestations
 */
contract AttestationRegistry is OwnableUpgradeable {
  PortalRegistry public portalRegistry;
  SchemaRegistry public schemaRegistry;

  uint256 private _attestationId;
  uint16 private version;

  mapping(uint256 attestationId => Attestation attestation) private attestations;

  /// @notice Error thrown when a non-portal tries to call a method that can only be called by a portal
  error OnlyPortal();
  /// @notice Error thrown when an invalid PortalRegistry address is given
  error PortalRegistryInvalid();
  /// @notice Error thrown when an invalid SchemaRegistry address is given
  error SchemaRegistryInvalid();
  /// @notice Error thrown when a portal is not registered in the PortalRegistry
  error PortalNotRegistered();
  /// @notice Error thrown when an attestation is already registered in the AttestationRegistry
  error AttestationAlreadyAttested();
  /// @notice Error thrown when a schema is not registered in the SchemaRegistry
  error SchemaNotRegistered();
  /// @notice Error thrown when an attestation is not registered in the AttestationRegistry
  error AttestationNotAttested();
  /// @notice Error thrown when an attempt is made to revoke an attestation by an entity other than the attesting portal
  error OnlyAttestingPortal();

  /// @notice Event emitted when an attestation is registered
  event AttestationRegistered(Attestation attestation);
  /// @notice Event emitted when an attestation is revoked
  event AttestationRevoked(uint256 attestationId);

  /// @notice Event emitted when the version number is incremented
  event VersionUpdated(uint16 version);

  /**
   * @notice Checks if the caller is a registered portal
   * @param portal the portal address
   */
  modifier onlyPortals(address portal) {
    bool isPortalRegistered = portalRegistry.isRegistered(portal);
    if (!isPortalRegistered) revert OnlyPortal();
    _;
  }

  /**
   * @notice Contract initialization
   */
  function initialize(address _portalRegistry, address _schemaRegistry) public initializer {
    __Ownable_init();

    if (_portalRegistry == address(0)) revert PortalRegistryInvalid();
    if (_schemaRegistry == address(0)) revert SchemaRegistryInvalid();
    portalRegistry = PortalRegistry(_portalRegistry);
    schemaRegistry = SchemaRegistry(_schemaRegistry);

    _attestationId = 1;
    version = 1;
  }

  /**
   * @notice Registers an attestation to the AttestationRegistry
   * @param attestation the attestation to register
   * @dev This method is only callable by a registered Portal
   */
  function attest(Attestation calldata attestation) external onlyPortals(msg.sender) {
    assert(attestation.attestationId == _attestationId);
    attestations[attestation.attestationId] = attestation;
    ++_attestationId;
    emit AttestationRegistered(attestation);
  }

  function getAttestationId() public view returns (uint256) {
    return _attestationId;
  }

  /**
   * @notice Checks if an attestation is registered
   * @param attestationId the attestation identifier
   * @return true if the attestation is registered, false otherwise
   */
  function isRegistered(uint256 attestationId) public view returns (bool) {
    return attestationId < _attestationId;
  }

  /**
   * @notice Gets an attestation by its identifier
   * @param attestationId the attestation identifier
   * @return the attestation
   */
  function getAttestation(uint256 attestationId) public view returns (Attestation memory) {
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
}
