pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract SimpleImp is EIP712 {
    constructor() EIP712("NAME", "VERSION") {}

    function validateSignature(bytes32 digest, bytes memory signature) public view {
        address signer = ECDSA.recover(digest, signature);
        require(signer == address(this), "Invalid signature");
    }

    function getDigest(uint256 number) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(number)));
    }

}