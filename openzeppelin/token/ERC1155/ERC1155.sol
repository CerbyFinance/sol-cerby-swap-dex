// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.12;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "../../utils/introspection/ERC165.sol";

abstract contract ERC1155 {
    // Mapping from token ID to account erc1155Balances
    mapping(uint256 => mapping(address => uint256)) erc1155Balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) erc1155OperatorApprovals;

    mapping(uint256 => uint256) erc1155TotalSupply;

    address constant BURN_ADDRESS = address(0);

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );

    error ERC1155_CallerIsNotOwnerNorApproved();
    error ERC1155_IdsLengthMismatch();
    error ERC1155_InsufficientBalanceForTransfer();
    error ERC1155_BurnAmountExceedsBalance();
    error ERC1155_ERC1155ReceiverRejectsTokens();
    error ERC1155_TransferToNonERC1155ReceiverImplementer();

    modifier addressIsApproved(address _addr) {
        if (_addr == msg.sender && isApprovedForAll(_addr, msg.sender)) {
            revert ERC1155_CallerIsNotOwnerNorApproved();
        }
        _;
    }

    modifier idsLengthMismatch(
        uint256 _idsLength, 
        uint256 _accountsLength
    ) {
        if (_idsLength != _accountsLength) {
            revert ERC1155_IdsLengthMismatch();
        }
        _;
    }

    function balanceOf(
        address _account, 
        uint256 _id
    )
        public
        view
        returns (uint256)
    {
        return erc1155Balances[_id][_account];
    }

    function isApprovedForAll(
        address _account, 
        address _operator
    )
        public
        view
        returns (bool)
    {
        return erc1155OperatorApprovals[_account][_operator];
    }

    function balanceOfBatch(
        address[] calldata _accounts, 
        uint256[] calldata _ids
    )
        external
        view
        idsLengthMismatch(_ids.length, _accounts.length)
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }

        return batchBalances;
    }

    function totalSupply(uint256 _id)
        external
        view
        returns (uint256)
    {
        return erc1155TotalSupply[_id];
    }

    function exists(uint256 _id)
        external
        view
        returns (bool)
    {
        return erc1155TotalSupply[_id] > 0;
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    )
        internal
    {
        address operator = msg.sender;

        uint256 fromBalance = erc1155Balances[_id][_from];
        if (fromBalance < _amount) {
            revert ERC1155_InsufficientBalanceForTransfer();
        }

        unchecked {
            erc1155Balances[_id][_from] = fromBalance - _amount;
            erc1155Balances[_id][_to] += _amount; // since user balance is lower than totalSupply and totalSupply can't overflow ==> user balance can't overflow
        }

        emit TransferSingle(
            operator,
            _from,
            _to,
            _id,
            _amount
        );

        _doSafeTransferAcceptanceCheck(operator, _from, _to, _id, _amount, "");
    }

    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount
    )
        internal
    {
        if (_amount == 0) {
            return;
        }

        address operator = msg.sender;

        erc1155TotalSupply[_id] += _amount; // will overflow (revert) earlier than erc1155Balances[_id][_to]

        unchecked {
            erc1155Balances[_id][_to] += _amount;
        }

        emit TransferSingle(operator, BURN_ADDRESS, _to, _id, _amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            BURN_ADDRESS,
            _to,
            _id,
            _amount,
            ""
        );
    }

    function _burn(
        address _from,
        uint256 _id,
        uint256 _amount
    )
        internal
    {
        address operator = msg.sender;

        uint256 fromBalance = erc1155Balances[_id][_from];

        if (fromBalance < _amount) {
            revert ERC1155_BurnAmountExceedsBalance();
        }

        unchecked {
            erc1155Balances[_id][_from] = fromBalance - _amount;
            erc1155TotalSupply[_id] -= _amount; // if user balance is not underflow then total supply isn't either
        }

        emit TransferSingle(operator, _from, BURN_ADDRESS, _id, _amount);
    }

    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    )
        internal
    {
        erc1155OperatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        private
    {
        if (isContract(_to)) {
            try
                IERC1155Receiver(_to).onERC1155Received(
                    _operator,
                    _from,
                    _id,
                    _amount,
                    _data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155_ERC1155ReceiverRejectsTokens();
                }
            } catch {
                revert ERC1155_TransferToNonERC1155ReceiverImplementer();
            }
        }
    }

    function isContract(address _account)
        private
        view
        returns (bool)
    {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }
}
