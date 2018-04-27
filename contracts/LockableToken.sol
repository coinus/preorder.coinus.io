pragma solidity 0.4.21;


/** @title LockableToken
  * @dev Base contract which allows token issuer control over when token transfer
  * is allowed globally as well as per address based.
  */
contract LockableToken {
    // global token transfer lock
    bool public globalTokenTransferLock;
    // token issuer
    address public owner;
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

    // Check if msg.sender is token issuer
    modifier isOwner {
        require(owner == msg.sender);
        _;
    }

    /**
      * @dev The LockableToken constructor sets the original `owner` of the
      * contract to the issuer, and sets global lock in locked state.
      */
    function LockableToken() public {
        globalTokenTransferLock = false;
        owner = msg.sender;
    }

    /**
      * @dev Allows token issuer to change global lock state.
      * @param locked true for locked and false for unlocked.
      * @return Current global lock state
      */
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
      * @return Current address lock state. true: unlocked, false: locked
      */
    function getTokenLockStatusForAddress(address target) public view
    returns (bool)
    {
        return lockedStatusAddress[target];
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
}
