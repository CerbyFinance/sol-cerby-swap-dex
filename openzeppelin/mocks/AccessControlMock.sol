// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";

contract AccessControlMock is AccessControl {
    constructor() {
        _setupRole(ROLE_ADMIN, _msgSender());
    }

    function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) public {
        _setRoleAdmin(roleId, adminRoleId);
    }

    function senderProtected(bytes32 roleId) public onlyRole(roleId) {}
}
