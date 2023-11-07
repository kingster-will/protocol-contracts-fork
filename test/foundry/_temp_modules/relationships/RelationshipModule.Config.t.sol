// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";

contract RelationshipModuleConfigTest is BaseTest {

    address relCreator = address(4444444);

    function setUp() override public {
        super.setUp();
        _grantRole(vm, AccessControl.RELATIONSHIP_MANAGER_ROLE, relCreator);
    }

    function test_RelationshipModule_addProtocolRelationshipType() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.ADDRESS,
            dst: LibRelationship.Relatables.ADDRESS
        });
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.prank(relCreator);
        // Todo test event
        spg.addRelationshipType(params);
        LibRelationship.RelationshipType memory relType = relationshipModule.getRelationshipType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            "TEST_RELATIONSHIP"
        );
        assertEq(relType.src, LibRelationship.NO_ADDRESS_RESTRICTIONS);
        assertEq(relType.srcSubtypesMask, 0);
        assertEq(relType.dst, LibRelationship.NO_ADDRESS_RESTRICTIONS);
        assertEq(relType.dstSubtypesMask, 0);
    }

    function test_RelationshipModule_removeProtocolRelationshipType() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.ADDRESS,
            dst: LibRelationship.Relatables.ADDRESS
        });
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.startPrank(relCreator);
        // Todo test event
        spg.addRelationshipType(params);
        spg.removeRelationshipType(LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP, "TEST_RELATIONSHIP");
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("RelationshipModule_RelTypeNotSet(string)", "TEST_RELATIONSHIP"));
        LibRelationship.RelationshipType memory relType = relationshipModule.getRelationshipType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            "TEST_RELATIONSHIP"
        );        assertEq(relType.src, address(0));
    }


    // function test_RelationshipModule_revert_addRelationshipTypeIpaWithoutAllowedTypes() public {}
}
