// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IDOPool.sol";
import "./interface/IIDOPool.sol";

contract BetFactory is OwnableUpgradeable {
    address[] public pools;
    // pool creater mapping
    mapping(address => bool) public superUsers;
    event PoolCreated(address indexed pool);
    event SuperUserAdded(address indexed user);
    event SuperUserDeleted(address indexed user);
    event Withdraw(uint256 amount);
    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Illegal address");
        _;
    }

    modifier onlySuper() {
        require(
            superUsers[msg.sender] == true,
            "LDO Factory::onlySuperUser: Not SuperUser"
        );
        _;
    }

    /**
     * @dev Initializes the contract.
     * @param _initialOwner The initial owner.
     */
    function initialize(address _initialOwner) public initializer {
        __Ownable_init(_initialOwner);
    }

    //参考LDOPool中的createPool

    function createPool(
        address _voteToken,
        uint256 _voteTokenLimit,
        uint256 _voteMaxAmount,
        uint256 _perVoteReward,
        address _idoTokenA,
        address _idoTokenB,
        uint256 _idoTokenAAmount,
        uint256 _idoTokenBAmount,
        uint256 _idoStartTime,
        uint256 _idoEndTime,
        uint256 _idoMaxAmountPerAddress
    ) public onlySuper returns (address) {
        require(
            _idoStartTime < _idoEndTime,
            "Start time must be before end time + 1 days"
        );
        require(
            block.timestamp < _idoStartTime,
            "Start time must be greater than now + 1 days"
        );
        require(_voteToken != address(0), "Vote Token not set");
        require(_idoTokenA != address(0), "IDO Token A not set");
        require(_idoTokenB != address(0), "IDO Token B not set");
        require(
            _idoTokenAAmount > 0,
            "IDO Token A amount must be greater than 0"
        );
        require(
            _idoTokenBAmount > 0,
            "IDO Token B amount must be greater than 0"
        );
        require(
            _idoMaxAmountPerAddress < _idoTokenBAmount,
            "IDO Max amount per address must be less than idoTokenBAmount"
        );

        bytes32 salt = keccak256(
            abi.encodePacked(
                _voteToken,
                _voteTokenLimit,
                _voteMaxAmount,
                _perVoteReward,
                _idoTokenA,
                _idoTokenB,
                _idoTokenAAmount,
                _idoTokenBAmount,
                _idoStartTime,
                _idoEndTime,
                _idoMaxAmountPerAddress,
                address(this)
            )
        );
        IDOPool pool = new IDOPool{salt: salt}(
            _voteToken,
            _voteTokenLimit,
            _voteMaxAmount,
            _perVoteReward,
            _idoTokenA,
            _idoTokenB,
            _idoTokenAAmount,
            _idoTokenBAmount,
            _idoStartTime,
            _idoEndTime,
            _idoMaxAmountPerAddress,
            address(this)
        );
        pools.push(address(pool));
        emit PoolCreated(address(pool));
        return address(pool);
    }

    /**
     * @dev Set Super User
     */
    function setSuperUser(
        address _user
    ) public onlyOwner onlyValidAddress(_user) {
        superUsers[_user] = true;
        emit SuperUserAdded(_user);
    }

    /**
     * @dev Detele Super User
     */
    function deleteSuperUser(
        address _user
    ) public onlyOwner onlyValidAddress(_user) {
        superUsers[_user] = false;
        delete superUsers[_user];
        emit SuperUserDeleted(_user);
    }

    /**
     * @dev withdraw pool address's Atoken
     */
    function withdrawTokenA(address _pool) public onlySuper {
        IIDOPool(_pool).withdrawTokenA();
    }

    /**
     * @dev withdraw pool address's Btoken
     */
    function withdrawTokenB(address _pool) public onlySuper {
        IIDOPool(_pool).withdrawTokenB();
    }

    /**
     * @dev withdraw pool address's other token
     */
    function withdrawOtherToken(
        address _pool,
        address _token
    ) public onlySuper {
        IIDOPool(_pool).withdrawOtherToken(_token);
    }

    /**
     * @dev factory withdraw MNT
     */
    function withdrawMNT(uint256 _amount) public onlySuper {
        payable(owner()).transfer(_amount);
        emit Withdraw(_amount);
    }

    /**
     * @dev factory withdraw ERC20 token
     */
    function withdrawERC20(address _token, uint256 _amount) public onlySuper {
        IERC20(_token).transfer(owner(), _amount);
        emit Withdraw(_amount);
    }

    /**
     * @dev Returns the pools.
     */
    function getPools() public view returns (address[] memory) {
        return pools;
    }
}
