// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;
import { Attestation } from "../../src/types/Structs.sol";

contract AttestationRegistryMock {
  uint256 public attestationId;
  uint16 public version;

  event AttestationRegistered();

  function test() public {}

  function attest(Attestation memory attestation) public {
    require(attestation.attestationId == attestationId, "Invalid Attestation ID");
    ++attestationId;
    emit AttestationRegistered();
  }

  function getAttestationId() public view returns (uint256) {
    return attestationId;
  }

  function getVersionNumber() public view returns (uint16) {
    return version;
  }
}
