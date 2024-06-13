// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IDOPool.sol";

contract BetFactory is OwnableUpgradeable {
    address[] public pools;
    // pool creater mapping
    mapping(address => address) public poolCreators;

    event PoolCreated(address indexed pool);

    /**
     * @dev Initializes the contract.
     * @param _initialOwner The initial owner.
     */
    function initialize(address _initialOwner) public initializer {
        __Ownable_init(_initialOwner);
    }

    //参考LDOPool中的createPool

    /**
     * @dev Returns the pools.
     */
    function getPools() public view returns (address[] memory) {
        return pools;
    }
}
