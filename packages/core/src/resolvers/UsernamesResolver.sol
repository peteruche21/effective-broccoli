// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@ens/contracts/resolvers/profiles/AddrResolver.sol";
import "@ens/contracts/registry/ENS.sol";
import "@ens/contracts/resolvers/Multicallable.sol";
import {ReverseClaimer} from "@ens/contracts/reverseRegistrar/ReverseClaimer.sol";
import {INameWrapper} from "@ens/contracts/wrapper/INameWrapper.sol";

contract UsernamesResolver is Multicallable, AddrResolver, ReverseClaimer {
    ENS immutable ens;
    INameWrapper immutable nameWrapper;
    address immutable trustedController;
    address immutable trustedReverseRegistrar;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => mapping(bytes32 => mapping(address => bool))) private _tokenApprovals;
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approved(
        address owner,
        bytes32 indexed node,
        address indexed delegate,
        bool indexed approved
    );

    constructor(
        ENS _ens,
        INameWrapper wrapperAddress,
        address _trustedETHController,
        address _trustedReverseRegistrar
    ) ReverseClaimer(_ens, msg.sender) {
        ens = _ens;
        nameWrapper = wrapperAddress;
        trustedController = _trustedETHController;
        trustedReverseRegistrar = _trustedReverseRegistrar;
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function approve(bytes32 node, address delegate, bool approved) external {
        require(msg.sender != delegate, "Setting delegate status for self");

        _tokenApprovals[msg.sender][node][delegate] = approved;
        emit Approved(msg.sender, node, delegate, approved);
    }

    function isApprovedFor(
        address owner,
        bytes32 node,
        address delegate
    ) public view returns (bool) {
        return _tokenApprovals[owner][node][delegate];
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        if (msg.sender == trustedController || msg.sender == trustedReverseRegistrar) {
            return true;
        }
        address owner = ens.owner(node);
        if (owner == address(nameWrapper)) {
            owner = nameWrapper.ownerOf(uint256(node));
        }
        return
            owner == msg.sender ||
            isApprovedForAll(owner, msg.sender) ||
            isApprovedFor(owner, node, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view override(Multicallable, AddrResolver) returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}
