pragma solidity 0.8.9;

///@dev  OpenZeppelin modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MetaGamezStakepool is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @dev Modifiers
    modifier stakeEnabled() {
        require(stakeOn == true, "Staking is paused !");
        _;
    }

    modifier withdrawEnabled() {
        require(withdrawOn == true, "Withdrawing is paused !");
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        require(_amount > uint256(1 ether), "Min amount is 1 token!");
        _;
    }
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    ///@dev Structs

    struct User {
        uint256 stakeBalance;
        uint256 rewards;
        uint256 stakingTime;
    }

    /// @dev Variables

    IERC20 public stakeToken;
    IERC20 public rewardToken;

    uint256 public apy;

    uint256 public tokenSupply;

    uint256 public totalStaked;

    bool public stakeOn;

    bool public withdrawOn;

    bool internal userAdressesOn;

    /// @dev Mapping

    mapping(address => User) public users;

    /// @dev Arrays
    address[] public userAdresses;

    /// @dev Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Deposited(address indexed user, uint256 amount);
    event TokenSupplyWithdrawn(address indexed user, uint256 amount);

    constructor(address _stakeToken, address _rewardToken)
        onlyValidAddress(_stakeToken)
        onlyValidAddress(_rewardToken)
    {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        apy = 17;
        stakeOn = true;
        withdrawOn = true;
        userAdressesOn = true;
    }

    function depositTokens(uint256 _amount)
        external
        onlyOwner
        onlyValidAmount(_amount)
    {
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        tokenSupply += _amount;

        emit Deposited(msg.sender, _amount);
    }

    function stake(uint256 _amount)
        external
        whenNotPaused
        stakeEnabled
        onlyValidAmount(_amount)
        nonReentrant
    {
        address _msgSender = msg.sender;

        stakeToken.safeTransferFrom(_msgSender, address(this), _amount);

        uint256 _reward = pendingRewardsOf(_msgSender);

        users[_msgSender].rewards += _reward;

        users[_msgSender].stakeBalance += _amount;

        users[_msgSender].stakingTime = block.timestamp;

        totalStaked += _amount;

        if (userAdressesOn) _checkOrAddUser(_msgSender);

        emit Staked(_msgSender, _amount);
    }

    function withdraw(uint256 _amount)
        public
        whenNotPaused
        withdrawEnabled
        nonReentrant
    {
        address _msgSender = msg.sender;
        require(balanceOf(_msgSender) >= _amount, "Not enough staked!");

        users[_msgSender].rewards += pendingRewardsOf(_msgSender);

        users[_msgSender].stakeBalance -= _amount;

        users[_msgSender].stakingTime = block.timestamp;

        stakeToken.safeTransfer(_msgSender, _amount);

        totalStaked -= _amount;

        emit Withdrawn(_msgSender, _amount);
    }

    function withdrawAll() external whenNotPaused withdrawEnabled nonReentrant {
        withdraw(users[msg.sender].stakeBalance);
    }

    function claimReward() external whenNotPaused nonReentrant {
        address _msgSender = msg.sender;

        users[_msgSender].rewards += pendingRewardsOf(_msgSender);

        uint256 _reward = rewardsOf(_msgSender);

        require(_reward > 0, "No rewards!");

        require(tokenSupply >= _reward, "Not enough tokens, try later");

        users[_msgSender].rewards = 0;

        users[_msgSender].stakingTime = block.timestamp;

        rewardToken.safeTransfer(_msgSender, _reward);

        tokenSupply -= _reward;

        emit RewardClaimed(_msgSender, _reward);
    }

    function _checkOrAddUser(address _user) internal returns (bool) {
        bool _new = true;
        for (uint256 i = 0; i < userAdresses.length; i++) {
            if (userAdresses[i] == _user) {
                _new = false;
                i = userAdresses.length;
            }
        }
        if (_new) {
            userAdresses.push(_user);
        }
        return _new;
    }

    /// @dev getters

    /// @return balance
    function balanceOf(address account) public view returns (uint256) {
        return users[account].stakeBalance;
    }

    /// @return user reward
    function rewardsOf(address account) public view returns (uint256) {
        return users[account].rewards;
    }

    function stakingTimeOf(address account) public view returns (uint256) {
        return users[account].stakingTime;
    }

    function pendingRewardsOf(address account) public view returns (uint256) {
        uint256 _tokens = ((balanceOf(account) * apy) / 100) / 52 weeks;
        uint256 _time = block.timestamp - stakingTimeOf(account);
        return (_tokens * _time);
    }

    /// @return userlist
    function getUserList() external view onlyOwner returns (address[] memory) {
        address[] memory userList = new address[](userAdresses.length);

        for (uint256 i = 0; i < userAdresses.length; i++) {
            userList[i] = userAdresses[i];
        }

        return userList;
    }

    /// @return no of total pending rewards
    function getTotalPendingRewards() external view returns (uint256) {
        uint256 _total = 0;

        for (uint256 i = 0; i < userAdresses.length; i++) {
            _total += pendingRewardsOf(userAdresses[i]);
        }
        return _total;
    }

    /// @dev Admin

    /// @dev admin contract controls stake
    function setDisableStake(bool _flag) external onlyOwner {
        stakeOn = _flag;
    }

    /// @dev admin contract controls withdraw
    function setDisableWithdraw(bool _flag) external onlyOwner {
        withdrawOn = _flag;
    }

    /// @dev admin contract controls token
    function changeRewardToken(address _rewardToken)
        external
        onlyOwner
        onlyValidAddress(_rewardToken)
    {
        /// @dev do some checks
        rewardToken = IERC20(_rewardToken);
    }

    /// @dev admin contract controls apy
    /// @dev Resets the APY
    /// @param _apy APY admin want to set for future
    function resetApy(uint256 _apy) public onlyOwner {
        /// @dev do some checks
        require(_apy > 0, "Invalid Apy!");

        for (uint256 i = 0; i < userAdresses.length; i++) {
            uint256 _reward = pendingRewardsOf(userAdresses[i]);

            users[userAdresses[i]].rewards += _reward;

            users[userAdresses[i]].stakingTime = block.timestamp;
        }

        apy = _apy;
    }

    /// @dev owner inters the reward tokens
    function returnRewardTokens() external onlyOwner {
        /// @dev do some checks
        require(tokenSupply > 0, "Not enough token supply!");

        uint256 _amount = tokenSupply;

        rewardToken.safeTransfer(msg.sender, tokenSupply);

        tokenSupply = 0;

        emit TokenSupplyWithdrawn(msg.sender, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}