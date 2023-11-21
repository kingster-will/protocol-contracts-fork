// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "contracts/ip-org/IPOrg.sol";
import "contracts/modules/licensing/TermsRepository.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermCategories, TermIds, TermsData } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import "contracts/StoryProtocol.sol";

 contract Main is Script, BroadcastManager, JsonDeploymentHandler, ProxyHelper {

     using StringUtil for uint256;
     using stdJson for string;
     using ShortStrings for string;

     constructor() JsonDeploymentHandler("main") {
     }

     function run() public {
         _beginBroadcast();
         _readDeployment();
         StoryProtocol storyProtol = StoryProtocol(_readAddress("$.main.StoryProtocol"));
         address ipOrg_ = address(0xb422E54932c1dae83E78267A4DD2805aa64A8061);

         Licensing.TermsConfig memory comTermsConfig = Licensing.TermsConfig({
             termIds: new ShortString[](0),
             termData: new bytes[](0)
         });

         ShortString[] memory termIds_ = new ShortString[](3);
         bytes[] memory termsData_ = new bytes[](3);
         termIds_[0] = TermIds.NFT_SHARE_ALIKE.toShortString();
         termsData_[0] = abi.encode(true);
         termIds_[1] = TermIds.LICENSOR_APPROVAL.toShortString();
         termsData_[1] = abi.encode(true);
         termIds_[2] = TermIds.LICENSOR_IPORG_OR_PARENT.toShortString();
         termsData_[2] = abi.encode(TermsData.LicensorConfig.IpOrg);

         Licensing.TermsConfig memory nonComTermsConfig = Licensing.TermsConfig({
             termIds: termIds_,
             termData: termsData_
         });

         Licensing.FrameworkConfig memory frameworkConfig_ = Licensing.FrameworkConfig({
             comTermsConfig: comTermsConfig,
             nonComTermsConfig: nonComTermsConfig
         });

         storyProtol.configureIpOrgLicensing(ipOrg_, frameworkConfig_);
         _endBroadcast();
     }
 }
