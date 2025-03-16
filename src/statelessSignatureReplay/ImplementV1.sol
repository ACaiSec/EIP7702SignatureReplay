pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./NonceStorage.sol";
contract ImplementV1 is EIP712 {
    bytes32 constant SALT = keccak256("IMP1");
    constructor() EIP712("NAME", "VERSION") {}

    function initialStorage() public returns (address storageAddress) {
        bytes memory bytecode = type(NonceStorage).creationCode;
        bytes memory deployCode = abi.encodePacked(bytecode, abi.encode(address(this)));
        storageAddress = Create2.deploy(0, SALT, deployCode);
    }

    function execute(bytes memory signature) public {
        address storageAddress = Create2.computeAddress(SALT, keccak256(abi.encodePacked(type(NonceStorage).creationCode, abi.encode(address(this)))));
        uint256 nonce = NonceStorage(storageAddress).useNonce();
        bytes32 digest = getDigest(nonce);
        validateSignature(digest, signature);
    }

    function validateSignature(bytes32 digest, bytes memory signature) public view {
        address signer = ECDSA.recover(digest, signature);
        require(signer == address(this), "Invalid signature");
    }

    // 添加一个返回恢复的签名者地址的函数，用于调试
    function validateSignatureAndReturn(bytes32 digest, bytes memory signature) public view returns (address) {
        return ECDSA.recover(digest, signature);
    }

    function getDigest(uint256 nonce) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(nonce)));
    }

}