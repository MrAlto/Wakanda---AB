//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Apartment is ERC721Enumerable {
  using Counters for Counters.Counter;

  Counters.Counter private _counter;

  address public immutable BUILDING;

  mapping(address => Property[]) public properties;

  struct Property {
    uint256 tokenId;
    uint256 buildingId;
    uint256 squareMeters;
    uint8 floor;
  }

  constructor(address _buildingContract) public ERC721("Appartment", "APT") {
    BUILDING = _buildingContract;
  }

  modifier onlyBuilding() {
    require(msg.sender == BUILDING);
    _;
  }

  /** @notice Create a new Apartment NFT **/
  /** @dev Only callable by Building contract **/
  function mint(
    address _owner,
    uint256 _buildingId,
    uint256 _squareMeters,
    uint8 _floor
  ) external onlyBuilding {
    _counter.increment();
    uint256 _tokenId = _counter.current();

    Property memory prop = Property(_tokenId, _buildingId, _squareMeters, _floor);

    properties[_owner].push(prop);
    _mint(_owner, _tokenId);
  }

  /** @notice Destroy a apartment NFT **/
  /** @dev Only callable by Building contract **/
  function burn(address _owner, uint256 _tokenId) external onlyBuilding {
    // Updates infos
    for (uint256 i = 0; i < properties[_owner].length; i++) {
      if (properties[_owner][i].tokenId == _tokenId) {
        _removeProperty(i, _owner);
      }
    }

    _burn(_tokenId);
  }

  // Checkers functions

  function getFloor(address _owner, uint256 _tokenId) external returns (uint8) {
    return _getFloor(_owner, _tokenId);
  }

  function getTotalSquareMeters(address _owner, uint256 _tokenId) external returns (uint256) {
    uint256 size;
    for (uint256 i = 0; i < properties[_owner].length; i++) {
      if (properties[_owner][i].tokenId == _tokenId) {
        size = properties[_owner][i].squareMeters;
      }
    }

    return size;
  }

  function isOnSameFloor(uint256[] calldata _ids, address _owner) external returns (bool) {
    bool res = true;

    for (uint256 i = 0; i < _ids.length; i++) {
      for (uint256 j = _ids.length - 1; j > 0; j--) {
        if (_getFloor(_owner, _ids[i]) != _getFloor(_owner, _ids[j])) {
          res = false;
          break;
        }
      }
    }

    return res;
  }

  function isProprietor(uint256 _id, address owner) external returns (bool) {
    return _isProprietor(_id, owner);
  }

  function isInBuilding(
    uint256 _buildingId,
    uint256 _id,
    address owner
  ) external returns (bool) {
    return _isInBuilding(_buildingId, _id, owner);
  }

  function isAllProprietor(uint256[] calldata _ids, address owner) external returns (bool) {
    bool res = true;

    for (uint256 i = 0; i < _ids.length; i++) {
      if (_isProprietor(_ids[i], owner) == false) {
        res = false;
      }
    }

    return res;
  }

  function isAllInBuilding(
    uint256 _buildingId,
    uint256[] calldata _ids,
    address owner
  ) external returns (bool) {
    bool res = true;

    for (uint256 i = 0; i < _ids.length; i++) {
      if (_isInBuilding(_buildingId, _ids[i], owner) == false) {
        res = false;
      }
    }

    return res;
  }

  // Internal functions

  function _getFloor(address _owner, uint256 _tokenId) internal returns (uint8) {
    uint8 floor = 0;
    for (uint256 i = 0; i < properties[_owner].length; i++) {
      if (properties[_owner][i].tokenId == _tokenId) {
        floor = properties[_owner][i].floor;
      }
    }
    return floor;
  }

  function _removeProperty(uint256 _index, address owner) internal {
    require(_index < properties[owner].length, "index out of bound");

    for (uint256 i = _index; i < properties[owner].length - 1; i++) {
      properties[owner][i] = properties[owner][i + 1];
    }
    properties[owner].pop();
  }

  function _isProprietor(uint256 _aptId, address owner) internal returns (bool) {
    bool res = false;
    for (uint256 i = 0; i < properties[owner].length; i++) {
      if (properties[owner][i].tokenId == _aptId) {
        res = true;
      }
    }

    return res;
  }

  function _isInBuilding(
    uint256 _buildingId,
    uint256 _aptId,
    address owner
  ) internal returns (bool) {
    bool res = false;
    uint256 buildingId;
    for (uint256 i = 0; i < properties[owner].length; i++) {
      if (properties[owner][i].tokenId == _aptId) {
        buildingId = properties[owner][i].buildingId;
      }
    }

    if (buildingId == _buildingId) {
      res = true;
    }
    return res;
  }
}
