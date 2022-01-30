// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal contractUri;

    mapping(uint256 => uint256) internal contractTotalSupply;

    address internal constant BURN_ADDRESS = address(0);

    error ERC1155_BalanceQueryForTheZeroAddress();
    error ERC1155_AccountsAndIdsLengthMismatch();
    error ERC1155_TransferToZeroAddress();
    error ERC1155_IdsAndAmountsLengthMismatch();
    error ERC1155_MintToZeroAddress();
    error ERC1155_InsufficientBalanceForTransfer();
    error ERC1155_BurnFromZeroAddress();
    error ERC1155_BurnAmountExceedsBalance();
    error ERC1155_SettingApprovalStatusForSelf();
    error ERC1155_ERC1155ReceiverRejectsTokens();
    error ERC1155_TransferToNonERC1155ReceiverImplementer();

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory _uri) {
        _setURI(_uri);
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 _id) external view virtual returns (uint256) {
        return contractTotalSupply[_id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 _id) external view virtual returns (bool) {
        return contractTotalSupply[_id] > 0;
    }

    function isContract(address _account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return contractUri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address _account, uint256 _id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (_account == BURN_ADDRESS) {
            revert ERC1155_BalanceQueryForTheZeroAddress();
        }

        return balances[_id][_account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids)
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256 idsLength = _ids.length;
        if (_accounts.length != idsLength) {
            revert ERC1155_AccountsAndIdsLengthMismatch();
        }

        uint256[] memory batchBalances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < idsLength; ++i) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address _account, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return operatorApprovals[_account][_operator];
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual {
        if (_to == BURN_ADDRESS) {
            revert ERC1155_TransferToZeroAddress();
        }

        address operator = msg.sender;

        uint256 fromBalance = balances[_id][_from];
        if (fromBalance < _amount) {
            revert ERC1155_InsufficientBalanceForTransfer();
        }

        unchecked {
            balances[_id][_from] = fromBalance - _amount;
        }
        balances[_id][_to] += _amount;
        unchecked {
            contractTotalSupply[_id] += _amount;
        }

        emit TransferSingle(operator, _from, _to, _id, _amount);

        _doSafeTransferAcceptanceCheck(operator, _from, _to, _id, _amount, _data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) internal virtual {
        uint256 idsLength = _ids.length;
        if (idsLength != _amounts.length) {
            revert ERC1155_IdsAndAmountsLengthMismatch();
        }

        if (_to == BURN_ADDRESS) {
            revert ERC1155_TransferToZeroAddress();
        }

        address operator = msg.sender;

        for (uint256 i = 0; i < idsLength; ++i) {
            uint256 amount = _amounts[i];

            uint256 fromBalance = balances[_ids[i]][_from];
            if (fromBalance < amount) {
                revert ERC1155_InsufficientBalanceForTransfer();
            }

            unchecked {
                balances[_ids[i]][_from] = fromBalance - amount;
            }
            balances[_ids[i]][_to] += amount;
            unchecked {
                contractTotalSupply[_ids[i]] += amount;
            }
        }

        emit TransferBatch(operator, _from, _to, _ids, _amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory _newContractUri) internal virtual {
        contractUri = _newContractUri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal virtual {
        if (_to == BURN_ADDRESS) {
            revert ERC1155_MintToZeroAddress();
        }

        if (_amount == 0) {
            return;
        }

        address operator = msg.sender;

        contractTotalSupply[_id] += _amount;

        unchecked {
            balances[_id][_to] += _amount;
        }

        emit TransferSingle(operator, BURN_ADDRESS, _to, _id, _amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            BURN_ADDRESS,
            _to,
            _id,
            _amount,
            _data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes memory _data
    ) internal virtual {
        if (_to == BURN_ADDRESS) {
            revert ERC1155_MintToZeroAddress();
        }

        uint256 idsLength = _ids.length;
        if (idsLength != _amounts.length) {
            revert ERC1155_IdsAndAmountsLengthMismatch();
        }

        address operator = msg.sender;

        for (uint256 i = 0; i < idsLength; i++) {
            contractTotalSupply[_ids[i]] += _amounts[i];

            unchecked {
                balances[_ids[i]][_to] += _amounts[i];
            }
        }

        emit TransferBatch(operator, BURN_ADDRESS, _to, _ids, _amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            BURN_ADDRESS,
            _to,
            _ids,
            _amounts,
            _data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal virtual {
        if (_from == BURN_ADDRESS) {
            revert ERC1155_BurnFromZeroAddress();
        }

        address operator = msg.sender;

        uint256 fromBalance = balances[_id][_from];
        if (fromBalance < _amount) {
            revert ERC1155_BurnAmountExceedsBalance();
        }
        unchecked {
            balances[_id][_from] = fromBalance - _amount;
            contractTotalSupply[_id] -= _amount;
        }

        emit TransferSingle(operator, _from, BURN_ADDRESS, _id, _amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) internal virtual {
        if (_from == BURN_ADDRESS) {
            revert ERC1155_BurnFromZeroAddress();
        }
        if (_ids.length != _amounts.length) {
            revert ERC1155_IdsAndAmountsLengthMismatch();
        }

        address operator = msg.sender;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];

            uint256 fromBalance = balances[id][_from];
            if (fromBalance < amount) {
                revert ERC1155_BurnAmountExceedsBalance();
            }

            unchecked {
                balances[id][_from] = fromBalance - amount;
                contractTotalSupply[id] -= amount;
            }
        }

        emit TransferBatch(operator, _from, BURN_ADDRESS, _ids, _amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual {
        if (_owner == _operator) {
            revert ERC1155_SettingApprovalStatusForSelf();
        }

        operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) private {
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

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes memory _data
    ) private {
        if (isContract(_to)) {
            try
                IERC1155Receiver(_to).onERC1155BatchReceived(
                    _operator,
                    _from,
                    _ids,
                    _amounts,
                    _data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155_ERC1155ReceiverRejectsTokens();
                }
            } catch {
                revert ERC1155_TransferToNonERC1155ReceiverImplementer();
            }
        }
    }
}
