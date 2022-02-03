//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IApartment.sol";

contract Building is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  address public aptContract;

  /** @notice used to handle decimals  */
  uint256 public immutable BASE_UNIT = 10**18;

  struct Estate {
    uint256 tokenId;
    uint256 squareMeters;
    uint256 sizeLeft;
    uint8 floors;
  }

  mapping(address => Estate[]) public buildings;

  constructor() public ERC721("Building", "BLD") {}

  /** @notice Create a new building NFT **/
  function mint(
    address _to,
    uint256 _tokenId,
    uint16 _squareMeters,
    uint8 _floors
  ) external onlyOwner {
    Estate memory prop = Estate(_tokenId, _squareMeters, _squareMeters, _floors);

    buildings[_to].push(prop);

    _mint(_to, _tokenId);
  }

  /** @notice Build an Apartment for a specific buyer **/
  function buildApt(
    uint256 _buildingId,
    uint16 _squareMeters,
    uint8 _floor,
    address buyer
  ) external {
    require(buildings[msg.sender].length > 0, "caller is not a building proprietor");
    require(_isProprietor(_buildingId), "caller is not the proprietor of that building");
    require(_hasEnoughSpace(_buildingId, _squareMeters), "not enough space");
    require(_floorReached(_buildingId, _floor), "max floor reached");

    IApartment(aptContract).mint(buyer, _buildingId, _squareMeters * BASE_UNIT, _floor);
    for (uint256 i = 0; i < buildings[msg.sender].length; i++) {
      if (buildings[msg.sender][i].tokenId == _buildingId) {
        uint256 sizeLeft = buildings[msg.sender][i].sizeLeft;
        sizeLeft = sizeLeft.sub(_squareMeters);

        // Decrease size lefted
        buildings[msg.sender][i].sizeLeft = sizeLeft;
      }
    }
  }

  /** @notice Merge multiple Apartments into a new one  **/
  function merge(uint256 _buildingId, uint256[] calldata _aptId) external {
    require(_aptId.length > 1, "cannot merge only one apartment");
    require(IApartment(aptContract).isAllProprietor(_aptId, msg.sender), "caller is not the proprietor of all given apartments");
    require(IApartment(aptContract).isAllInBuilding(_buildingId, _aptId, msg.sender), "apartments are not in this building");
    require(IApartment(aptContract).isOnSameFloor(_aptId, msg.sender), "apartments need to be on the same floor");

    // Get floor number
    uint8 floor = IApartment(aptContract).getFloor(msg.sender, _aptId[0]);

    // Get total size of given apartments
    uint256 newSize;

    for (uint256 i; i < _aptId.length; i++) {
      newSize = newSize.add(IApartment(aptContract).getTotalSquareMeters(msg.sender, _aptId[i]));
    }

    // Burn the old ones
    for (uint256 i; i < _aptId.length; i++) {
      IApartment(aptContract).burn(msg.sender, _aptId[i]);
    }

    // Mint the new apartment
    IApartment(aptContract).mint(msg.sender, _buildingId, newSize, floor);
  }

  /** @notice Split one Apartments into multiples  **/
  function split(
    uint256 _buildingId,
    uint256 _aptId,
    uint256 _nbSplit
  ) external {
    require(_nbSplit > 1, "cannot split in one");
    require(IApartment(aptContract).isProprietor(_aptId, msg.sender), "caller is not the proprietor of the apartments");
    require(IApartment(aptContract).isInBuilding(_buildingId, _aptId, msg.sender), "the apartment is not in this building");

    // Get floor number
    uint8 floor = IApartment(aptContract).getFloor(msg.sender, _aptId);

    // Get total size of given apartment
    uint256 totalSize = IApartment(aptContract).getTotalSquareMeters(msg.sender, _aptId);

    // Burn the old one
    IApartment(aptContract).burn(msg.sender, _aptId);

    // Mint the new apartments
    for (uint256 i = 0; i < _nbSplit; i++) {
      IApartment(aptContract).mint(msg.sender, _buildingId, totalSize.div(_nbSplit), floor);
    }
  }

  /** RESTRICTED FUNCTIONS **/

  function setAptContract(address _aptContract) external onlyOwner {
    aptContract = _aptContract;
  }

  /** INTERNAL FUNCTIONS **/

  function _isProprietor(uint256 _idBuilding) internal returns (bool) {
    bool res = false;
    for (uint256 i = 0; i < buildings[msg.sender].length; i++) {
      if (buildings[msg.sender][i].tokenId == _idBuilding) {
        res = true;
      }
    }

    return res;
  }

  function _hasEnoughSpace(uint256 _idBuilding, uint256 _squareMeters) internal returns (bool) {
    bool res = false;
    for (uint256 i = 0; i < buildings[msg.sender].length; i++) {
      if (buildings[msg.sender][i].tokenId == _idBuilding) {
        if (buildings[msg.sender][i].sizeLeft > _squareMeters) {
          res = true;
        }
      }
    }

    return res;
  }

  function _floorReached(uint256 _idBuilding, uint8 _floor) internal returns (bool) {
    bool res = true;

    for (uint256 i = 0; i < buildings[msg.sender].length; i++) {
      if (buildings[msg.sender][i].tokenId == _idBuilding) {
        if (_floor > buildings[msg.sender][i].floors) {
          res = false;
        }
      }
    }

    return res;
  }
}
