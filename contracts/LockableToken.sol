pragma solidity 0.4.21;


/** @title LockableToken
  * @dev Base contract which allows token issuer control over when token transfer
  * is allowed globally as well as per address based.
  */
contract LockableToken {
    // token issuer
    address public owner;

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
        owner = msg.sender;
    }
}
