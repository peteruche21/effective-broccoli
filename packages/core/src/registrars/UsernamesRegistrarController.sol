// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@usernames/library/Errors.sol";
import "@usernames/interfaces/IUsernamesRegistrarController.sol";
import "@ens/contracts/utils/ERC20Recoverable.sol";
import {StringUtils} from "@ens/contracts/ethregistrar/StringUtils.sol";
import {ReverseRegistrar} from "@usernames/registrars/ReverseRegistrar.sol";
import {UsernamesResolver, ReverseClaimer, INameWrapper} from "@usernames/resolvers/UsernamesResolver.sol";
import {BaseRegistrarImplementation, IERC165, ENS} from "@ens/contracts/ethregistrar/BaseRegistrarImplementation.sol";

struct Price {
    uint256 base;
    uint256 premium;
}

/// minimal name registrar without commitments
/// hardcoded name prices
/// hardcoded premium
contract UsernamesRegistrarController is IERC165, ERC20Recoverable, ReverseClaimer {
    using StringUtils for *;

    ReverseRegistrar public immutable reverseRegistrar;
    INameWrapper public immutable nameWrapper;
    BaseRegistrarImplementation immutable base;

    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 baseCost,
        uint256 premium,
        uint256 expires
    );
    event NameRenewed(string name, bytes32 indexed label, uint256 cost, uint256 expires);

    constructor(
        BaseRegistrarImplementation _base,
        ReverseRegistrar _reverseRegistrar,
        INameWrapper _nameWrapper,
        ENS _ens,
        address _owner
    ) ReverseClaimer(_ens, msg.sender) Ownable(_owner) {
        base = _base;
        reverseRegistrar = _reverseRegistrar;
        nameWrapper = _nameWrapper;
    }

    function rentPrice(
        string memory name,
        uint256 duration
    ) public pure returns (Price memory price) {
        // explicitly defining prices without oracles
        uint256 len = name.strlen();
        uint256 basePrice;
        // hardcoded name prices
        if (len >= 5) {
            basePrice = .001e18 * duration;
        } else if (len == 4) {
            basePrice = .002e18 * duration;
        } else if (len == 3) {
            basePrice = .003e18 * duration;
        } else if (len == 2) {
            basePrice = .004e18 * duration;
        } else {
            basePrice = .01e18 * duration;
        }
        price = Price({base: basePrice, premium: 0});
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) public payable {
        Price memory price = rentPrice(name, duration);
        if (msg.value < price.base + price.premium) {
            revert InsufficientValue();
        }

        uint256 expires = nameWrapper.registerAndWrapETH2LD(
            name,
            owner,
            duration,
            resolver,
            ownerControlledFuses
        );

        if (data.length > 0) {
            _setRecords(resolver, keccak256(bytes(name)), data);
        }

        if (reverseRecord) {
            _setReverseRecord(name, resolver, msg.sender);
        }

        emit NameRegistered(
            name,
            keccak256(bytes(name)),
            owner,
            price.base,
            price.premium,
            expires
        );

        if (msg.value > (price.base + price.premium)) {
            payable(msg.sender).transfer(msg.value - (price.base + price.premium));
        }
    }

    function renew(string calldata name, uint256 duration) external payable {
        bytes32 labelhash = keccak256(bytes(name));
        uint256 tokenId = uint256(labelhash);
        Price memory price = rentPrice(name, duration);
        if (msg.value < price.base) {
            revert InsufficientValue();
        }
        uint256 expires = nameWrapper.renew(tokenId, duration);

        if (msg.value > price.base) {
            payable(msg.sender).transfer(msg.value - price.base);
        }

        emit NameRenewed(name, labelhash, price.base, expires);
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IUsernamesRegistrarController).interfaceId;
    }

    function _setRecords(address resolverAddress, bytes32 label, bytes[] calldata data) internal {
        // use hardcoded .bit namehash
        bytes32 nodehash = keccak256(abi.encodePacked(bytes32(0x0), label));
        UsernamesResolver resolver = UsernamesResolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
    }

    function _setReverseRecord(string memory name, address resolver, address owner) internal {
        reverseRegistrar.setNameForAddr(msg.sender, owner, resolver, string.concat(name, ".bit"));
    }
}
