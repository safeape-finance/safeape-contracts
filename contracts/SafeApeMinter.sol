pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./libs/IBEP20.sol";

// SafeApe Minter with USDA in the contracts.
contract SafeApeMinter is Ownable, ReentrancyGuard {
    // The USDA TOKEN!
    IBEP20 public safeApe;

    // The operator can only withdraw wrong tokens in the contract
    address private _operator;

    // Event
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
    event OperatorTokenRecovery(address tokenRecovered, uint256 amount);

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    constructor(IBEP20 _safeApe) public {
        safeApe = _safeApe;
        _operator = _msgSender();

        emit OperatorTransferred(address(0), _operator);
    }

    // Safe USDA transfer function, just in case if rounding error causes pool to not have enough USDAs.
    function safeUSDATransfer(address _to, uint256 _amount)
        public
        onlyOwner
        nonReentrant
    {
        uint256 usdaBal = safeApe.balanceOf(address(this));
        if (_amount > usdaBal) {
            _amount = usdaBal;
        }
        if (_amount > 0) {
            safeApe.transfer(_to, _amount);
        }
    }

    /**
     * @dev operator of the contract
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external onlyOperator {
        require(
            newOperator != address(0),
            "SafeApeMinter::transferOperator: new operator is the zero address"
        );
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    /**
     * @notice It allows the operator to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by operator.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOperator
    {
        IBEP20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit OperatorTokenRecovery(_tokenAddress, _tokenAmount);
    }
}
