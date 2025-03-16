// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ImplementV1} from "../src/statelessSignatureReplay/ImplementV1.sol";
import {ImplementV2} from "../src/statelessSignatureReplay/ImplementV2.sol";
import {NonceStorage} from "../src/statelessSignatureReplay/NonceStorage.sol";

contract SignatureReplayTest is Test {
    // EOA 的地址和私钥
    address payable constant EOA_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant EOA_PRIVATE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // 调用者的地址和私钥（将代表 EOA 执行交易）
    address constant CALLER_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant CALLER_PRIVATE_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    // 实现合约和存储合约
    ImplementV1 public implementation1;
    ImplementV2 public implementation2;
    address public storageAddress1;
    address public storageAddress2;

    function setUp() public {
        // 部署实现合约
        implementation1 = new ImplementV1();
        implementation2 = new ImplementV2();
    }

    function testExecute() public {
        // EOA delegates implementation1 contract and deploys storage contract of implementation1
        vm.signAndAttachDelegation(address(implementation1), EOA_PRIVATE_KEY);
        storageAddress1 = ImplementV1(address(EOA_ADDRESS)).initialStorage();
        console2.log("storageAddress1", storageAddress1);

        // EOA uses EIP712 to sign the message with nonce 0 (Which can be replayed)
        bytes32 digest = ImplementV1(address(EOA_ADDRESS)).getDigest(0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(EOA_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Log the digest, signer, and contract address for debugging
        console2.log("Digest:", uint256(digest));
        console2.log("Signer:", EOA_ADDRESS);
        console2.log("Contract:", address(implementation1));
        console2.log("r:", uint256(r));
        console2.log("s:", uint256(s));
        console2.log("v:", uint256(v));
        
        address recoveredSigner = ImplementV1(address(EOA_ADDRESS)).validateSignatureAndReturn(digest, signature);
        console2.log("Recovered signer:", recoveredSigner);

        // EOA executes the message with the signature
        ImplementV1(address(EOA_ADDRESS)).execute(signature);

        // Verify that the nonce has been increased
        NonceStorage nonceStor = NonceStorage(storageAddress1);
        assertEq(nonceStor.nonce(), 1);
    }

    function testSignatureReplay() public {
        // EOA delegates implementation1 contract and deploys storage contract of implementation1
        vm.signAndAttachDelegation(address(implementation1), EOA_PRIVATE_KEY);
        storageAddress1 = ImplementV1(address(EOA_ADDRESS)).initialStorage();
        console2.log("storageAddress1", storageAddress1, "\n");

        // EOA uses EIP712 to sign the message with nonce 0 (Which can be replayed)
        bytes32 digest = ImplementV1(address(EOA_ADDRESS)).getDigest(0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(EOA_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Log signature components
        console2.log("r:", uint256(r));
        console2.log("s:", uint256(s));
        console2.log("v:", uint256(v), "\n");

        // Verify and use the signature in implementation1
        ImplementV1(address(EOA_ADDRESS)).execute(signature);

        // Verify that the nonce has been increased in storageAddress1
        NonceStorage nonceStor1 = NonceStorage(storageAddress1);
        assertEq(nonceStor1.nonce(), 1);

        // EOA delegates implementation2 contract and deploys storage contract of implementation2
        vm.signAndAttachDelegation(address(implementation2), EOA_PRIVATE_KEY);
        storageAddress2 = ImplementV2(address(EOA_ADDRESS)).initialStorage();
        console2.log("storageAddress2", storageAddress2, "\n");

        // Verify and replay the signature in implementation2
        ImplementV2(address(EOA_ADDRESS)).execute(signature);

        // Verify that the nonce has been increased in storageAddress2
        NonceStorage nonceStor2 = NonceStorage(storageAddress2);
        assertEq(nonceStor2.nonce(), 1);
    }
} 