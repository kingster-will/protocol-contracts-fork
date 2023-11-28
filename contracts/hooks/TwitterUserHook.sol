// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { AsyncBaseHook } from "contracts/hooks/base/AsyncBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title TokenGatedHook
/// @notice This contract is a hook that ensures the user is the owner of a specific NFT token.
/// @dev It extends SyncBaseHook and provides the implementation for validating the hook configuration and executing the hook.
contract TwitterUserHook is AsyncBaseHook {

    /// @notice Constructs the TokenGatedHook contract.
    /// @param accessControl_ The address of the access control contract.
    constructor(address accessControl_) AsyncBaseHook(accessControl_) {}

    /// @notice Validates the configuration for the hook.
    /// @dev This function checks if the tokenAddress is a valid ERC721 contract.
    /// @param hookConfig_ The configuration data for the hook.
    function _validateConfig(bytes memory hookConfig_) internal view override {
    }

    /// @dev Internal function to request an asynchronous call,
    /// concrete hoot implementation should override the function.
    /// The function should revert in case of error.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return hookData The data returned by the hook.
    /// @return requestId The ID of the request.
    function _requestAsyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal override returns (bytes memory hookData, bytes32 requestId) {
        return ("", bytes32(0));
    }

    /// @dev Internal function to get the address of the callback caller.
    /// concrete hoot implementation should override the function.
    /// @param requestId_ The ID of the request.
    /// @return The address of the callback caller.
    function _callbackCaller(bytes32 requestId_) internal view override returns (address) {
        return address(0);
    }
}
