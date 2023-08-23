// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { AttestationRegistry } from "../AttestationRegistry.sol";
import { ModuleRegistry } from "../ModuleRegistry.sol";
import { AbstractPortal } from "../interface/AbstractPortal.sol";
import { Attestation, AttestationPayload, Portal } from "../types/Structs.sol";

/**
 * @title Default Portal
 * @author Consensys
 * @notice This contract aims to provide a default portal
 */
contract DefaultPortal is Initializable, AbstractPortal {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(
    address[] memory _modules,
    address _moduleRegistry,
    address _attestationRegistry
  ) AbstractPortal(_modules, _moduleRegistry, _attestationRegistry) {
    _disableInitializers();
  }

  /**
   * @notice Contract initialization
   */
  function initialize(
    address[] calldata _modules,
    address _moduleRegistry,
    address _attestationRegistry
  ) public initializer {
    // Store module registry and attestation registry addresses and modules
    attestationRegistry = AttestationRegistry(_attestationRegistry);
    moduleRegistry = ModuleRegistry(_moduleRegistry);
    modules = _modules;
  }

  function _beforeAttest(Attestation memory attestation, uint256 value) internal override {}

  function _afterAttest(Attestation memory attestation, uint256 value) internal override {}
}
