// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// import ierc20 & safemath & non-standard
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract FiatPresale is Ownable {
    using SafeMath for uint256;

    // uint256 public oneMonthTime = 2591999;
    // for testing purpose 5 sec time
    uint256 public oneMonthTime = 10;
    IERC20 public token;
    mapping(address => uint256) public claimable;

    IERC20 public dai;
    struct User{
        uint256 time;
        uint256 amountpaid;
        uint256 months;
        uint256 tokenamount;
        uint256 daiamount;
        uint256 rate;
    }
    
    mapping(address => User) public users;
    mapping(address => bool) public registeredusers;

    constructor( address _token,address _dai) public {
        token = IERC20(_token);
        dai = IERC20(_dai);
    }
    
    // function to add user
    function addUser(address _address , uint256 _noofmonths ,uint256 _tokenamount, uint256 _totaldai) public onlyOwner {
        require(!registeredusers[msg.sender],'you are not registered');
        users[_address] = User(now + oneMonthTime.mul(_noofmonths),0,_noofmonths,_tokenamount,_totaldai,_tokenamount.div(_totaldai));
        registeredusers[_address] = true;
    }
    
  
    
    function payinstallment(address _addr) public view returns(uint256) {
        require(registeredusers[_addr],'you are not registered');
        
       
        if(now > users[_addr].time){
            return users[_addr].daiamount;
        }    
        uint timeleft = users[_addr].time.sub(now);
    
        uint amt = users[_addr].daiamount.div(users[_addr].months);
        uint j;
        for(uint i = users[_addr].months;i>0;i--){
            if(timeleft <= oneMonthTime || timeleft == 0){
                return amt.mul(users[_addr].months);
            }
            j= j.add(1);
            if(timeleft > i.sub(1).mul(oneMonthTime)){
                return amt.mul(j);
            }
        }
    }
    
    function pendingamt() public view returns(uint256){
        uint paidamt = users[msg.sender].amountpaid;
        uint payamt = payinstallment(msg.sender).sub(paidamt);
        return payamt;
    }
    
    function payyourinstallment(uint _amount) external {
        require(payinstallment(msg.sender) > 0);
        uint paidamt = users[msg.sender].amountpaid;
        require(paidamt < payinstallment(msg.sender));
        uint payamt = payinstallment(msg.sender).sub(paidamt);
        require(_amount <= payamt);
        dai.transferFrom(msg.sender,address(this),_amount);
        token.transfer(msg.sender,_amount.mul(users[msg.sender].rate));
        users[msg.sender].amountpaid  =  users[msg.sender].amountpaid.add(_amount);
    }
    
    
    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function adminTokenTrans() external onlyOwner{
        require(getTokenBalance() > 0,'the contract has no pry tokens');
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }

    function adminTransferFund(uint256 value) external onlyOwner {
        msg.sender.call{value: value}("");
    }
}
