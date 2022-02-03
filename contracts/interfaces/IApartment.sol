//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IApartment {
  function mint(
    address _owner,
    uint256 _buildingId,
    uint256 _size,
    uint8 _floor
  ) external;

  function burn(address _owner, uint256 _tokenId) external;

  function isProprietor(uint256 _id, address owner) external returns (bool);

    function isInBuilding(uint256 _buildingId, uint256 _id, address owner) external returns (bool);

  function isAllProprietor(uint256[] calldata _ids, address owner) external returns (bool);

  function isAllInBuilding(
    uint256 _buildingId,
    uint256[] calldata _ids,
    address owner
  ) external returns (bool);

  function isOnSameFloor(uint256[] calldata _ids, address owner) external returns (bool);

  function getTotalSquareMeters(address owner, uint256 _tokenId) external returns (uint256);

  function getFloor(address _owner, uint256 _tokenId) external returns (uint8);
}
