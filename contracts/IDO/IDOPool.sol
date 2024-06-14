// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract IDOPool is Ownable, Pausable {
    // voteToken 投票token
    address public voteToken;
    // voteTokenLimit 持有token操作数量可参与投票
    uint256 public voteTokenLimit;
    //voteMaxAmount 投票数量，大于投票数量后，用户可参与IDO，大于数量无法参与投票
    uint256 public voteMaxAmount;
    // perVoteReward 每次投票奖励数量
    uint public perVoteReward;

    // 已经voteAmount 投票数量
    uint256 public voteAmount;
    // voteUser 已经投票用户，用户只可投票一次
    mapping(address => bool) public voteUser;
    // vote claimed record
    mapping(address => bool) public voteClaimed;

    //vote claim amout
    uint256 public voteClaimAmount;

    // IDO Token A 目标代币 USDT or MNT
    address public idoTokenA;
    // IDO Token B 项目代币 EVO-Token
    address public idoTokenB;
    // TokenA decimals
    uint256 public idoTokenADecimals;
    // TokenB decimals
    uint256 public idoTokenBDecimals;

    // IDO Token A 目标代币数量 比如USDT
    uint256 public idoTokenAAmount;
    // IDO Token B 项目代币数量 比如EVO-Token
    uint256 public idoTokenBAmount;
    // 每个A代币对应的B代币数量 1USDT = xxx EVO
    uint256 public idoTokenAPrice;
    // IDO 开始时间
    uint256 public idoStartTime;
    // IDO 结束时间
    uint256 public idoEndTime;
    // IDO 参与单地址最大投注额
    uint256 public idoMaxAmountPerAddress;

    //当前已经参与IDO数量
    uint256 public idoAmount;
    // IDO 参与地址及金额
    mapping(address => uint256) public idoAddressAmount;

    // Token B的总数量 = idoTokenBAmount + perVoteReward * voteMaxAmount
    uint256 public totalTokenBAmount;

    //claim record
    mapping(address => bool) public claimRecord;

    //claim amount
    uint256 public claimAmount;

    using SafeERC20 for IERC20;

    event Vote(address indexed user);
    event VoteClaimed(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event Withdraw(address token, uint256 amount);

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Illegal address");
        _;
    }

    /*
     * @dev Initializes the contract.
     * @param _voteToken The token to vote with.
     * @param _voteTokenLimit The vote token limit.
     * @param _voteMaxAmount The max vote amount.
     * @param _perVoteReward The reward of vote.
     * @param _idoTokenA The token to ido with.
     * @param _idoTokenB The token to ido with.
     * @param _idoTokenAAmount The amount of ido token A.
     * @param _idoTokenBAmount The amount of ido token B.
     * @param _idoStartTime The start time of the ido.
     * @param _idoEndTime The end time of the ido.
     * @param _idoMaxAmountPerAddress The max amount per address.
     
     */

    //constructor中定义上面的public变量，自动生成代码
    constructor(
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
        uint256 _idoMaxAmountPerAddress,
        address _owner
    ) Ownable(_owner) {
        require(
            _idoStartTime < _idoEndTime + 1 days,
            "Start time must be before end time + 1 days"
        );
        require(
            block.timestamp + 1 days < _idoStartTime,
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
        voteToken = _voteToken;
        voteTokenLimit = _voteTokenLimit;
        voteMaxAmount = _voteMaxAmount;
        perVoteReward = _perVoteReward;

        idoTokenA = _idoTokenA;
        idoTokenB = _idoTokenB;
        idoTokenAAmount = _idoTokenAAmount;
        idoTokenBAmount = _idoTokenBAmount;
        idoStartTime = _idoStartTime;
        idoEndTime = _idoEndTime;
        idoMaxAmountPerAddress = _idoMaxAmountPerAddress;
        idoTokenBDecimals = IERC20Metadata(_idoTokenB).decimals();
        totalTokenBAmount = idoTokenBAmount + perVoteReward * voteMaxAmount;
        if (idoTokenA == address(0)) {
            idoTokenADecimals = 18;
        } else {
            idoTokenADecimals = IERC20Metadata(_idoTokenA).decimals();
        }

        if (idoTokenADecimals == 0) {
            idoTokenAPrice = _idoTokenBAmount / _idoTokenAAmount;
        } else {
            idoTokenAPrice =
                ((10 ** idoTokenADecimals) * _idoTokenBAmount) /
                _idoTokenBAmount;
        }
    }

    /**
     * @dev Votes for the IDO.
     * 用户持有voteTokenLimit数量的token，可参与投票
     * 合约中token B数量 >= idoTokenBAmount + perVoteReward * voteMaxAmount
     */
    function vote() public whenNotPaused {
        if (voteToken == address(0)) {
            require(
                msg.sender.balance >= voteTokenLimit,
                "Insufficient ETH balance to vote"
            );
        } else {
            require(
                IERC20(voteToken).balanceOf(_msgSender()) >= voteTokenLimit,
                "Insufficient vote token"
            );
        }
        require(
            IERC20(idoTokenB).balanceOf(address(this)) >= totalTokenBAmount,
            "Token B amount is not enough"
        );
        require(voteUser[_msgSender()] == false, "User already voted");
        require(voteAmount < voteMaxAmount, "Vote amount is full");
        voteUser[_msgSender()] = true;
        voteAmount += 1;

        emit Vote(_msgSender());
    }

    /**
     * @dev Claims the vote reaward.
     * 用户投票后，结束时间后可领取奖励
     */
    function claimVote() public whenNotPaused {
        require(voteAmount == voteMaxAmount, "Vote amount is not full");
        require(voteUser[_msgSender()] == true, "User didn't vote");
        IERC20(idoTokenB).safeTransfer(_msgSender(), perVoteReward);
        voteClaimed[_msgSender()] = true;
        voteUser[_msgSender()] = false;
        voteClaimAmount += perVoteReward;
        emit VoteClaimed(_msgSender(), perVoteReward);
    }

    /**
     * @dev Deposit for the IDO.
     * voteAmount = voteMaxAmount时，用户可参与IDO
     * 合约中token B数量 >= idoTokenBAmount + perVoteReward * voteMaxAmount
     * idoAmount 必须小于 idoTokenAAmount
     * 时间在IDO开始时间和结束时间之间
     */
    function _deposit(uint256 amount) public whenNotPaused {
        require(voteAmount == voteMaxAmount, "Vote amount is not full");
        require(
            IERC20(idoTokenA).balanceOf(_msgSender()) >= amount,
            "Insufficient ido token A"
        );
        require(
            IERC20(idoTokenA).allowance(_msgSender(), address(this)) >= amount,
            "IDOFund doesn't have enough allowance"
        );
        require(
            IERC20(idoTokenB).balanceOf(address(this)) >= totalTokenBAmount,
            "Token B amount is not enough"
        );
        require(
            idoAddressAmount[_msgSender()] + amount <= idoMaxAmountPerAddress,
            "Exceeds the max amount per address"
        );
        require(idoAmount + amount <= idoTokenAAmount, "IDO amount is full");
        require(
            block.timestamp >= idoStartTime && block.timestamp <= idoEndTime,
            "IDO time is not valid"
        );

        idoAddressAmount[_msgSender()] += amount;
        idoAmount += amount;

        emit Deposit(_msgSender(), amount);
    }

    function DepositERC20(uint256 amount) public whenNotPaused {
        require(idoTokenA != address(0), "Cannot deposit with MNT");
        _deposit(amount);
        IERC20(idoTokenA).safeTransferFrom(_msgSender(), address(this), amount);
    }

    function DepositMNT() public payable whenNotPaused {
        require(idoTokenA == address(0), "Cannot deposit with erc20 token");
        _deposit(msg.value);
    }

    /**
     * @dev Claims the IDO.
     * 用户参与IDO后，结束时间后可领取IDO Token B
     */
    function claim() public whenNotPaused {
        require(
            block.timestamp >= idoEndTime,
            "Claim time must be after ido end time"
        );
        require(idoAddressAmount[_msgSender()] > 0, "No IDO amount");

        uint256 amount = idoAddressAmount[_msgSender()];
        idoAddressAmount[_msgSender()] = 0;
        claimRecord[_msgSender()] = true;
        claimAmount += amount * idoTokenAPrice;
        IERC20(idoTokenB).safeTransfer(_msgSender(), amount * idoTokenAPrice);

        emit Claimed(_msgSender(), amount * idoTokenAPrice);
    }

    /**
     * @dev Withdraws the token.
     *
     */
    function withdrawTokenA() public onlyOwner {
        if (idoTokenA == address(0)) {
            uint256 amount = address(this).balance;
            (bool success, ) = payable(_msgSender()).call{value: amount}("");
            require(success, "Transfer failed");
            emit Withdraw(idoTokenA, amount);
        } else {
            uint256 amount = IERC20(idoTokenA).balanceOf(address(this));
            IERC20(idoTokenA).safeTransfer(_msgSender(), amount);
            emit Withdraw(idoTokenA, amount);
        }
    }

    /**
     * @dev Withdraws the token.
     *
     */
    function withdrawTokenB() public onlyOwner {
        uint256 amount = IERC20(idoTokenB).balanceOf(address(this));
        uint256 availableAmount = amount -
            idoAmount *
            idoTokenAPrice -
            perVoteReward *
            voteMaxAmount;
        if (availableAmount > 0) {
            IERC20(idoTokenB).safeTransfer(owner(), availableAmount);
            emit Withdraw(idoTokenB, amount);
        }
    }

    /**
     * @dev Withdraws the token.
     *
     */
    function withdrawOtherToken(address token) public onlyOwner {
        require(
            token != idoTokenA && token != idoTokenB,
            "Cannot withdraw ido token"
        );
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), amount);
        emit Withdraw(token, amount);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() public onlyOwner {
        _pause();
        emit Paused(_msgSender());
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(_msgSender());
    }
}
