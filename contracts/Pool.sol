// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/*The most common and basic form of access control is the concept of ownership: there’s an account that is the owner of a contract 
and can do administrative tasks on it. This approach is perfectly reasonable for contracts that have a single administrative user.
OpenZeppelin Contracts provides Ownable for implementing ownership in your contracts.*/
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Pool is AccessControl {

    event Deposit(address indexed _address, uint256 _value);
    event Withdraw(address indexed _address, uint256 _value);

    bytes32 public constant TEAM_MEMBER_ROLE = keccak256("TEAM_MEMBER_ROLE");

    uint256 public total;

    address[] public users;

    struct DepositValue {
        uint256 value;
        bool hasValue;
    }

    mapping(address => DepositValue) public deposits;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_MEMBER_ROLE, msg.sender);
    }

    receive() external payable {
                
        if(!deposits[msg.sender].hasValue) // only pushes new users
            users.push(msg.sender);

        deposits[msg.sender].value += msg.value;
        deposits[msg.sender].hasValue = true;

        total += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function depositRewards() public payable {
        require(hasRole(TEAM_MEMBER_ROLE, msg.sender), "Caller is not a team member");
        require(total > 0); // No rewards to distribute if the pool is empty.

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            uint256 rewards = ((deposits[user].value * msg.value) / total);

            deposits[user].value += rewards;
        }
    }

    function withdraw() public {
        uint256 deposit = deposits[msg.sender].value;

        require(deposit > 0, "You don't have anything left to withdraw");

        deposits[msg.sender].value = 0;

        (bool success, ) = msg.sender.call{value: deposit}("");

        require(success, "Transfer failed");

        emit Withdraw(msg.sender, deposit);
    }

    function addTeamMember(address account) public {
        grantRole(TEAM_MEMBER_ROLE, account);
    }

    function removeTeamMember(address account) public {
        revokeRole(TEAM_MEMBER_ROLE, account);
    }

    function getTotalSupplyPool() view public returns (uint256 totalSupply) {
        return total;
    }
}
