// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple ERC721 implementation with transient storage.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol)
abstract contract TransientERC721 {

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev The token does not exist.
    error TokenDoesNotExist();

    /// @dev The token already exists.
    error TokenAlreadyExists();

    /// @dev Cannot query the balance for the zero address.
    error BalanceQueryForZeroAddress();

    /// @dev Only the token owner or an approved account can manage the token.
    error NotOwnerNorApproved();

    /// @dev The token must be owned by `from`.
    error TransferFromIncorrectOwner();

    /// @dev Cannot mint or transfer to the zero address.
    error TransferToZeroAddress();

    /// @dev Cannot safely transfer to a contract that does not implement
    /// the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];
        if (owner == address(0)) revert TokenDoesNotExist();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                        TRANSIENT APPROVAL SLOTS
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant TRANSIENT_APPROVAL_SLOT = keccak256("TRANSIENT_APPROVAL_SLOT");
    bytes32 public constant TRANSIENT_APPROVAL_FOR_ALL_SLOT = keccak256("TRANSIENT_APPROVAL_FOR_ALL_SLOT");

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NotOwnerNorApproved();

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function transientApprove(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender] && !isTransientApprovedForAll(owner, msg.sender)) revert NotOwnerNorApproved();

        bytes32 locationApproved = _transientApprovalLocation(id);

        assembly {
            tstore(locationApproved, spender)
        }

        emit Approval(owner, spender, id);
    }

    function getTransientApproved(uint256 id) public virtual returns (address spender) {
        bytes32 location = _transientApprovalLocation(id);

        assembly {
            spender := tload(location)
        }
        
    }

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

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (from != _ownerOf[id]) revert TransferFromIncorrectOwner();

        if (to == address(0)) revert TransferToZeroAddress();

        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id]) revert NotOwnerNorApproved();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function transientTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (from != _ownerOf[id]) revert TransferFromIncorrectOwner();

        if (to == address(0)) revert TransferToZeroAddress();

        if (msg.sender != from && !isTransientApprovedForAll(from, msg.sender) && msg.sender != getTransientApproved(id)) revert NotOwnerNorApproved();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        _deleteTransientApprovalLocation(id);

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
                ERC721TokenReceiver.onERC721Received.selector) revert TransferToNonERC721ReceiverImplementer();
    }

    function safeTransientTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transientTransferFrom(from, to, id);

        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
                ERC721TokenReceiver.onERC721Received.selector) revert TransferToNonERC721ReceiverImplementer();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
                ERC721TokenReceiver.onERC721Received.selector) revert TransferToNonERC721ReceiverImplementer();
    }

    function safeTransientTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transientTransferFrom(from, to, id);

        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
                ERC721TokenReceiver.onERC721Received.selector) revert TransferToNonERC721ReceiverImplementer();
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        if (_ownerOf[id] != address(0)) revert TokenAlreadyExists();

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) revert TokenDoesNotExist();

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _transientBurn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) revert TokenDoesNotExist();

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        _deleteTransientApprovalLocation(id);

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
                ERC721TokenReceiver.onERC721Received.selector) revert TransferToNonERC721ReceiverImplementer();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
                ERC721TokenReceiver.onERC721Received.selector) revert TransferToNonERC721ReceiverImplementer();
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL APPROVAL LOCATION GETTER
    //////////////////////////////////////////////////////////////*/

    function _transientApprovalLocation(uint256 id) internal virtual returns (bytes32 location) {
        location = keccak256(abi.encode(id, uint256(TRANSIENT_APPROVAL_SLOT)));
    }

    function _transientApprovalLocationForAll(address owner, address operator) internal virtual returns (bytes32 location) {
        location = keccak256(
            abi.encode(
                operator,
                keccak256(abi.encode(owner, uint256(TRANSIENT_APPROVAL_FOR_ALL_SLOT)))
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL APPROVAL LOCATION CLEAR
    //////////////////////////////////////////////////////////////*/

    function _deleteTransientApprovalLocation(uint256 id) internal virtual {
        bytes32 location = keccak256(abi.encode(id, uint256(TRANSIENT_APPROVAL_SLOT)));

        assembly {
            tstore(location, 0)
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}