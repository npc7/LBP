// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IIDOPool {
    function withdrawTokenA() external;

    function withdrawTokenB() external;

    function withdrawOtherToken(address token) external;
}
