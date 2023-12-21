// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";
import { StoryProtocol } from "contracts/StoryProtocol.sol";
import { RelationshipModule } from "contracts/modules/relationships/RelationshipModule.sol";
import { LicensingModule } from "contracts/modules/licensing/LicensingModule.sol";
import { SPUMLParams } from "contracts/lib/modules/SPUMLParams.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { Errors } from "contracts/lib/Errors.sol";
import {JsonDeploymentHandler } from "script/foundry/utils/JsonDeploymentHandler.s.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { LicensingFrameworkRepo } from "contracts/modules/licensing/LicensingFrameworkRepo.sol";

contract Main is Script, BroadcastManager, JsonDeploymentHandler {
    using ShortStrings for *;

    address constant AZUKI_ADDRESS = address(0xED5AF388653567Af2F388E6224dC7C4b3241C544);
    uint constant AZUKI_TOKEN_ID = 3803;
    string constant FRAMEWORK_AZUKI = "AZUKI_JONNY";

    uint256 mainnetFork;
    string MAINNET_RPC_URL;
    StoryProtocol storyProtol;
    LicensingFrameworkRepo licensingFrameworkRepo;
    address ipaRegistry;
    address ipOrg;

    constructor() JsonDeploymentHandler("main") {}


    function run() public {
        _beginBroadcast();
        _readDeployment();
        storyProtol = StoryProtocol(_readAddress("$.main.StoryProtocol"));
        licensingFrameworkRepo = LicensingFrameworkRepo(_readAddress("$.main.LicensingFrameworkRepo"));
        ipaRegistry = _readAddress("$.main.IPAssetRegistry");

        // 1. Register IPOrg
        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "CHARACTER";
        ipOrg = storyProtol.registerIpOrg(
            multisig,
            "AZUKI JONNY",
            "AZKJNY",
            ipAssetTypes
        );
        console.log("ipOrg: %s", ipOrg);

        // 2. Configure Licensing
        _config_license();

        // 3. Register IP Asset
        Registration.RegisterIPAssetParams memory params = Registration
            .RegisterIPAssetParams({
            owner: multisig,
            ipOrgAssetType: 0,
            name: "Azuki 3803",
            hash: 0x0,
            mediaUrl: ""
        });

        (uint gIpaId, uint ipOrgAssetId) = storyProtol.registerIPAsset(
            ipOrg,
            params,
            0,
            new bytes[](0),
            new bytes[](0)
        );
        console.log("gIpaId: %s", gIpaId);
        console.log("ipOrgAssetId: %s", ipOrgAssetId);

        // 4. Create Relationship
        LibRelationship.RelatedElements memory allowedElements = LibRelationship
            .RelatedElements({
            src: LibRelationship.Relatables.Ipa,
            dst: LibRelationship.Relatables.ExternalNft
        });
        LibRelationship.AddRelationshipTypeParams
        memory relProtocolLevelParams = LibRelationship
            .AddRelationshipTypeParams({
            relType: "NFT_COLLECTION_ENTRY",
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: allowedElements,
            allowedSrcs:  new uint8[](0),
            allowedDsts:  new uint8[](0)
        });
        storyProtol.addRelationshipType(relProtocolLevelParams);

        LibRelationship.CreateRelationshipParams
        memory crParams = LibRelationship.CreateRelationshipParams({
            relType: "NFT_COLLECTION_ENTRY",
            srcAddress: ipaRegistry,
            srcId: gIpaId,
            dstAddress: AZUKI_ADDRESS,
            dstId: AZUKI_TOKEN_ID
        });

        console.log("added relation type");

        uint relId = storyProtol.createRelationship(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            crParams,
            new bytes[](0),
            new bytes[](0)
        );
        console.log("relId: %s", relId);

        // 5. Create License
        Licensing.LicenseCreation memory lCreation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0),
            parentLicenseId: 0, // no parent
            ipaId: gIpaId
        });

        uint licenseId = storyProtol.createLicense(
            ipOrg,
            lCreation,
            new bytes[](0),
            new bytes[](0)
        );
        console.log("licenseId: %s", licenseId);
        _endBroadcast();
    }

    function _config_license() internal {
        Licensing.ParamDefinition[]
        memory paramDefs = new Licensing.ParamDefinition[](3);
        ShortString[] memory derivativeChoices = new ShortString[](2);
        derivativeChoices[0] = SPUMLParams
            .ALLOWED_WITH_RECIPROCAL_LICENSE
            .toShortString();
        derivativeChoices[1] = SPUMLParams
            .ALLOWED_WITH_ATTRIBUTION
            .toShortString();

        paramDefs[0] = Licensing.ParamDefinition(
            SPUMLParams.ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(true),
            ""
        );
        paramDefs[1] = Licensing.ParamDefinition(
            SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(true),
            ""
        );
        paramDefs[2] = Licensing.ParamDefinition({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice,
            defaultValue: "",
            availableChoices: abi.encode(derivativeChoices)
        });

        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: FRAMEWORK_AZUKI,
                textUrl: "https://www.notion.so/storyprotocol/Mainnet-Mini-Launch-3685557fada047f2b5ef00a3275ab2d1?pvs=4#156341bd3c9b4a36ba83308c078ffe38",
                paramDefs: paramDefs
            })
        );

        uint8[] memory enabledDerivativeIndex = new uint8[](1);
        enabledDerivativeIndex[0] = SPUMLParams.ALLOWED_WITH_ATTRIBUTION_INDEX;
        // Use the list of terms from SPUMLParams
        Licensing.ParamValue[] memory lParams = new Licensing.ParamValue[](3);

        lParams[0] = Licensing.ParamValue({
            tag: SPUMLParams.ATTRIBUTION.toShortString(),
            value: abi.encode(true) // unset
        });
        lParams[1] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            value: abi.encode(true)
        });
        lParams[2] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            value: abi.encode(BitMask.convertToMask(enabledDerivativeIndex))
        });

        Licensing.LicensingConfig memory licensingConfig = Licensing
            .LicensingConfig({
            frameworkId: FRAMEWORK_AZUKI,
            params: lParams,
            licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });

        storyProtol.configureIpOrgLicensing(ipOrg, licensingConfig);

    }

}
