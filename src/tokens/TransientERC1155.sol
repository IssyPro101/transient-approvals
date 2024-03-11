// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract TransientERC1155 {

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Only the token owner or an approved account can manage the tokens.
    error NotOwnerNorApproved();

    /// @dev The lengths of the input arrays are not the same.
    error ArrayLengthsMismatch();

    /// @dev Cannot safely transfer to a contract that does not implement
    /// the ERC1155Receiver interface.
    error TransferToNonERC1155ReceiverImplementer();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                        TRANSIENT APPROVAL SLOTS
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant TRANSIENT_APPROVAL_SLOT = keccak256("TRANSIENT_APPROVAL_SLOT");
    bytes32 public constant TRANSIENT_APPROVAL_FOR_ALL_SLOT = keccak256("TRANSIENT_APPROVAL_FOR_ALL_SLOT");

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function setTransientApprovalForAll(address operator, bool approved) public virtual {
        bytes32 location = _transientApprovalLocationForAll(msg.sender, operator);

        assembly {
            tstore(location, approved)
        }


        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isTransientApprovedForAll(address owner, address operator) public virtual returns (bool approved) {
        bytes32 location = _transientApprovalLocationForAll(owner, operator);

        assembly {
            approved := tload(location)
        }
        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) revert NotOwnerNorApproved();

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length == 0) {
            if (to == address(0)) revert TransferToNonERC1155ReceiverImplementer();
        } else {
            if (ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) !=
                    ERC1155TokenReceiver.onERC1155Received.selector) revert TransferToNonERC1155ReceiverImplementer();
        }
    }

    function safeTransientTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        if (msg.sender != from && !isTransientApprovedForAll(from, msg.sender)) revert NotOwnerNorApproved();

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length == 0) {
            if (to == address(0)) revert TransferToNonERC1155ReceiverImplementer();
        } else {
            if (ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) !=
                    ERC1155TokenReceiver.onERC1155Received.selector) revert TransferToNonERC1155ReceiverImplementer();
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        if (ids.length != amounts.length) revert ArrayLengthsMismatch();

        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) revert NotOwnerNorApproved();

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length == 0) {
            if (to == address(0)) revert TransferToNonERC1155ReceiverImplementer();
        } else {
            if (ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) !=
                    ERC1155TokenReceiver.onERC1155Received.selector) revert TransferToNonERC1155ReceiverImplementer();
        }
    }

    function safeBatchTransientTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        if (ids.length != amounts.length) revert ArrayLengthsMismatch();

        if (msg.sender != from && !isTransientApprovedForAll(from, msg.sender)) revert NotOwnerNorApproved();

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length == 0) {
            if (to == address(0)) revert TransferToNonERC1155ReceiverImplementer();
        } else {
            if (ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) !=
                    ERC1155TokenReceiver.onERC1155Received.selector) revert TransferToNonERC1155ReceiverImplementer();
        }
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) revert ArrayLengthsMismatch();

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);


        if (to.code.length == 0) {
            if (to == address(0)) revert TransferToNonERC1155ReceiverImplementer();
        } else {
            if (ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) !=
                    ERC1155TokenReceiver.onERC1155Received.selector) revert TransferToNonERC1155ReceiverImplementer();
        }
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (idsLength != amounts.length) revert ArrayLengthsMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length == 0) {
            if (to == address(0)) revert TransferToNonERC1155ReceiverImplementer();
        } else {
            if (ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) !=
                    ERC1155TokenReceiver.onERC1155Received.selector) revert TransferToNonERC1155ReceiverImplementer();
        }
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (idsLength != amounts.length) revert ArrayLengthsMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL APPROVAL LOCATION GETTER
    //////////////////////////////////////////////////////////////*/

    function _transientApprovalLocationForAll(address owner, address operator) internal virtual returns (bytes32 location) {
        location = keccak256(
            abi.encode(
                operator,
                keccak256(abi.encode(owner, uint256(TRANSIENT_APPROVAL_FOR_ALL_SLOT)))
            )
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}