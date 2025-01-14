// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Portal } from "../../src/types/Structs.sol";

contract PortalRegistryMock {
  event PortalRegistered(string name, string description, address portalAddress);

  mapping(address id => Portal portal) private portals;

  function test() public {}

  function register(
    address id,
    string memory name,
    string memory description,
    bool isRevocable,
    string memory ownerName
  ) external {
    Portal memory newPortal = Portal(id, name, description, new address[](0), isRevocable, msg.sender, ownerName);
    portals[id] = newPortal;
    emit PortalRegistered(name, description, id);
  }

  function isRegistered(address id) public view returns (bool) {
    return portals[id].id != address(0);
  }

  function getPortalByAddress(address id) public view returns (Portal memory) {
    return portals[id];
  }
}
