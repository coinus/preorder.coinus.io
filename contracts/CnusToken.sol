pragma solidity 0.4.21;

import "./LockableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


/** @title CNUS Token
  * An ERC20-compliant token that is transferable only after preordered product
  * reception is confirmed. Once the product is used by the holder, token lock
  * will be automatically released.
  */
contract CnusToken is MintableToken, LockableToken, BurnableToken {
    using SafeMath for uint256;

    string public name = "CoinUs";
    string public symbol = "CNUS";
    uint256 public decimals = 18;

    // global token transfer lock
    bool public globalTokenTransferLock;

    // mapping that provides address based lock. default at the time of issueance
    // is locked, and will not be transferrable until explicit unlock call for
    // the address.
    mapping( address => bool ) public lockedStatusAddress;

    event Locked(address lockedAddress);
    event Unlocked(address unlockedaddress);

    // Check for global lock status to be unlocked
    modifier checkGlobalTokenTransferLock {
        require(!globalTokenTransferLock);
        _;
    }

    // Check for address lock to be unlocked
    modifier checkAddressLock {
        require(!lockedStatusAddress[msg.sender]);
        _;
    }

    function setGlobalTokenTransferLock(bool locked) public
    isOwner
    returns (bool)
    {
        globalTokenTransferLock = locked;
        return globalTokenTransferLock;
    }

    /**
      * @dev Allows token issuer to lock token transfer for an address.
      * @param target Target address to lock token transfer.
      */
    function initialLockAddress(address target) public
    onlyOwner
    {
        require(owner != target);
        lockedStatusAddress[target] = true;
        emit Locked(target);
    }

    /**
      * @dev Allows token issuer to lock token transfer for an address.
      * @param target Target address to lock token transfer.
      */
    function lockAddress(address target) public
    isOwner
    {
        require(owner != target);
        lockedStatusAddress[target] = true;
        emit Locked(target);
    }

    /**
      * @dev Allows token issuer to unlock token transfer for an address.
      * @param target Target address to unlock token transfer.
      */
    function unlockAddress(address target) public
    isOwner
    {
        lockedStatusAddress[target] = false;
        emit Unlocked(target);
    }

    /** @dev Transfer `_value` token to `_to` from `msg.sender`, on the condition
      * that global token lock and individual address lock in the `msg.sender`
      * accountare both released.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transfer(address _to, uint256 _value)
    public
    checkGlobalTokenTransferLock
    checkAddressLock
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /** @dev Send `_value` token to `_to` from `_from` on the condition
      * that global token lock and individual address lock in the `from` account
      * are both released.
      * @param _from The address of the sender.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transferFrom(address _from, address _to, uint256 _value)
    public
    checkGlobalTokenTransferLock
    checkAddressLock
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}
