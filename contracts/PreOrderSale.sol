pragma solidity 0.4.21;

import "./CnusToken.sol";
import "zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";


/** @title Preorder sale
  * Contract that governs this preorder. Preorder will validate ea
  */
contract PreOrderSale is TimedCrowdsale, Ownable {
    using SafeMath for uint256;

    MintableToken public token;
    // Check for preorder status
    bool public isFinalized = false;
    // Preorder amount total capacity
    uint256 public cap;
    // Check for preorder running status
    bool public crowdsaleActive = true;
    // Purchase amount limit in ether
    uint256 private constant PERSONAL_CAP = 10 * (10**18);

    // Holds preorder purchaser's acount address, total purchase amount, and
    // issued token balance.
    struct PreOrderAccount {
        bool exists; // false if new. true if previous preorder exists
        address account; // purchaser address
        uint256 amount; //amount
        uint256 balance; //token value
    }

    // A mapping of PreOrderAccount to a given address
    mapping(address => PreOrderAccount) public _preOrder;
    address[] private preOrderAddress;

    // Check if msg.sender previously made preorders.
    modifier isExists() {
        require(_preOrder[msg.sender].amount < PERSONAL_CAP);
        _;
    }

    event Finalized();
    event StartCrowdsale();
    event StopCrowdsale();
    event LogBountyTokenMinted(address minter, address beneficiary, uint256 amount);

    function PreOrderSale
    (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address _wallet,
        uint256 _cap,
        MintableToken _token
    )

    public
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_cap > 0);
        cap = _cap;
        token = _token;
    }

    // returns true if preorder amount exceeds capacity. Otherwise, false.
    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    // returns preorder amount at a given address.
    function amountOf(address beneficiary) public constant returns(uint256)
    {
        return _preOrder[beneficiary].amount;
    }

    // returns token amount issued at a given address.
    function balanceOf(address beneficiary) public constant returns(uint256)
    {
        return _preOrder[beneficiary].balance;
    }

    // returns preorder address count
    function getPreOrderAddressLength() public constant returns (uint256) {
        return preOrderAddress.length;
    }

    // returns address from preorder index
    function getPreOrderAddressAt(uint256 index) public constant returns (address) {
        return preOrderAddress[index];
    }

    //
    function createBountyToken(address beneficiary, uint256 amount) public onlyOwner returns(bool) {
        token.mint(beneficiary, amount);
        emit LogBountyTokenMinted(msg.sender, beneficiary, amount);
        return true;
    }

    /**
      * @dev Allows owner to start/unpause preorder.
      */
    function funcStartCrowdsale() public onlyOwner {
        require(!crowdsaleActive);
        require(!isFinalized);
        crowdsaleActive = true;
        emit StartCrowdsale();
    }

    /**
      * @dev Allows owner to stop/pause preorder.
      */
    function funcStopCrowdsale() public onlyOwner {
        require(crowdsaleActive);
        crowdsaleActive = false;
        emit StopCrowdsale();
    }

    /**
      * @dev Allows owner to finalize the preorder.
      */
    function finalize() public onlyOwner {
        require(!isFinalized);
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    /**
      * @dev Mint the token amount to the msg.sender only if the mintable amountOf
      * does not exceed forthset capacity.
      * @param _beneficiary Preorder purchaser.
      * @param _tokenAmount token amount to be transferred.
      */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(MintableToken(token).mint(_beneficiary, _tokenAmount));
        (LockableToken(token)).lockAddress(_beneficiary);
    }

    /**
      * @dev Pre-validates the purchase.
      * @param _beneficiary Preorder purchaser.
      * @param _weiAmount Token amount to be transferred for this purchase.
      */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
    internal isExists
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(!isFinalized);
        require(_weiAmount >= 0.1 ether && _weiAmount <= 10.0 ether);
        require(weiRaised.add(_weiAmount) <= cap);
        require(crowdsaleActive);
        PreOrderAccount storage crowdData = _preOrder[_beneficiary];
        if (crowdData.exists) {
            require(crowdData.amount.add(_weiAmount) <= PERSONAL_CAP);
        }
    }

    /**
      * @dev Store the preorder information after purchase is successful.
      * @param _beneficiary Preorder purchaser.
      * @param _weiAmount Token amount to be transferred for this purchase.
      */
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        PreOrderAccount storage crowdData = _preOrder[_beneficiary];
        crowdData.account = _beneficiary;
        crowdData.amount = crowdData.amount.add(_weiAmount);
        crowdData.balance = crowdData.balance.add(_getTokenAmount(_weiAmount));
        _preOrder[msg.sender] = crowdData;
        if (!crowdData.exists) {
            crowdData.exists = true;
            preOrderAddress.push(msg.sender);
        }
    }

    /** Fininalization of this preorder. If the amount raised from this preorder
      * is below the forthset capacity, the remainder will be minted and transferred
      * to token issuer.
      */
    function finalization() private {
        if (weiRaised < cap) {
            uint256 remainRaised = cap.sub(weiRaised);
            require(remainRaised > 0);
            token.mint(owner, _getTokenAmount(remainRaised));
        }
        funcStopCrowdsale();
        token.finishMinting();
        token.transferOwnership(msg.sender);
    }
}
