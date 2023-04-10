# ERC-6120 Reentrancy Vulnerability POC

The router returns unspent funds to the caller, but doesn't check if a call is
reentrant and doesn't segregate the funds of concurrent calls, so a reentrant
call can transfer 0 tokens into the router and the router will refund the
reentrant call funds deposited into the router from the outer call.

```console
$ forge test
[⠆] Compiling...
[⠊] Compiling 1 files with 0.8.19
[⠢] Solc 0.8.19 finished in 1.65s
Compiler run successful

Running 2 tests for test/UniversalTokenRouter.t.sol:UTRTest
[PASS] test_erc20CanBeExtractedFromUTRWithoutPermission() (gas: 790604)
[PASS] test_ethCanBeExtractedFromUTRWithoutPermission() (gas: 667810)
Test result: ok. 2 passed; 0 failed; finished in 1.46s
```
