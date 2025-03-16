pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NonceStorage is Ownable {
    uint256 public nonce;
    constructor(address initialOwner) Ownable(initialOwner) {}
    function useNonce() public onlyOwner returns (uint256 currentNonce) {
        currentNonce = nonce;
        nonce++;
    }
}