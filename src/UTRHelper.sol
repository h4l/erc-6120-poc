// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {Input, Action, Output} from "./UniversalTokenRouter.sol";

library UTRHelper {
    // values with a single 1-bit are preferred
    uint constant TRANSFER_FROM_SENDER = 0;
    uint constant TRANSFER_FROM_ROUTER = 1;
    uint constant TRANSFER_CALL_VALUE = 2;
    uint constant IN_TX_PAYMENT = 4;
    uint constant ALLOWANCE_BRIDGE = 8;

    uint constant AMOUNT_EXACT = 0;
    uint constant AMOUNT_ALL = 1;

    uint constant EIP_ETH = 0;

    uint constant ID_721_ALL =
        uint(keccak256("UniversalTokenRouter.ID_721_ALL"));

    uint constant ACTION_IGNORE_ERROR = 1;
    uint constant ACTION_RECORD_CALL_RESULT = 2;
    uint constant ACTION_INJECT_CALL_RESULT = 4;

    function actions() public pure returns (Action[] memory _actions) {
        _actions = new Action[](0);
    }

    function actions(
        Action memory a1
    ) public pure returns (Action[] memory _actions) {
        _actions = new Action[](1);
        _actions[0] = a1;
    }

    function actions(
        Action memory a1,
        Action memory a2
    ) public pure returns (Action[] memory _actions) {
        _actions = new Action[](2);
        _actions[0] = a1;
        _actions[1] = a2;
    }

    function inputs() public pure returns (Input[] memory _inputs) {
        _inputs = new Input[](0);
    }

    function inputs(
        Input memory i1
    ) public pure returns (Input[] memory _inputs) {
        _inputs = new Input[](1);
        _inputs[0] = i1;
    }

    function inputs(
        Input memory i1,
        Input memory i2
    ) public pure returns (Input[] memory _inputs) {
        _inputs = new Input[](2);
        _inputs[0] = i1;
        _inputs[1] = i2;
    }

    function outputs() public pure returns (Output[] memory _outputs) {
        _outputs = new Output[](0);
    }

    function outputs(
        Output memory o1
    ) public pure returns (Output[] memory _outputs) {
        _outputs = new Output[](1);
        _outputs[0] = o1;
    }

    function outputs(
        Output memory o1,
        Output memory o2
    ) public pure returns (Output[] memory _outputs) {
        _outputs = new Output[](1);
        _outputs[0] = o1;
        _outputs[1] = o2;
    }
}
