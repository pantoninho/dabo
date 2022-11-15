// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DABO.sol";

contract DABOfficeTest is Test {
    DABO public dabo;
    DABOffice public office;
    DABets public betsMock;
    DABV public dabvMock;
    DABets.Proposal[] public proposalsToBeValidated;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(10));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        vm.assume(a != address(dabo.dabv()));
        vm.assume(a != address(dabo.dab()));
        vm.assume(a != address(dabo.bookie()));
        vm.assume(a != address(dabo.bets()));
        vm.assume(a != address(dabo.treasury()));
        vm.assume(a != address(dabo.office()));
        vm.assume(a != address(0x4e59b44847b379578588920cA78FbF26c0B4956C)); // create2deployer? wtf is this?
        _;
    }

    function setUp() public {
        dabo = new DABO();
        office = dabo.office();
        betsMock = dabo.bets();
        dabvMock = dabo.dabv();

        while (proposalsToBeValidated.length > 0) {
            proposalsToBeValidated.pop();
        }
    }

    function testStartValidationRound() public {
        uint256 numberOfValidators = 2000; // max between 150000-200000 and gast cost is very high. how to increase this?
        uint256[] memory betIds;
        address[] memory validators = _mockValidators(numberOfValidators);

        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        _mockProposalToBeValidated(1, betIds, block.timestamp - 100);
        office.startValidationRound(1);

        uint256 proposal1Validators = 0;

        for (uint256 i = 0; i < validators.length; i++) {
            vm.prank(validators[i]);
            uint256[] memory pendingValidations = office
                .getPendingProposalValidations();

            for (uint256 j = 0; j < pendingValidations.length; j++) {
                if (pendingValidations[j] == 1) {
                    proposal1Validators++;
                }
            }
        }

        assertEq(
            proposal1Validators,
            _getRequiredNumberOfValidators(validators.length)
        );
    }

    function testStartValidationRoundInvalidProposalId() public {
        _mockValidators(100);
        vm.expectRevert(ProposalNotFound.selector);
        office.startValidationRound(1);
    }

    function testStartValidationRoundNotReadyProposal() public {
        _mockValidators(100);
        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        uint256[] memory betIds;
        _mockProposalToBeValidated(1, betIds, currentTimestamp + 1000);

        vm.expectRevert(ProposalNotReadyForValidation.selector);
        office.startValidationRound(1);
    }

    function testStartValidationRoundWhileRunning() public {
        _mockValidators(100);
        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        uint256[] memory betIds;
        _mockProposalToBeValidated(1, betIds, currentTimestamp - 100);

        office.startValidationRound(1);

        vm.expectRevert(CurrentValidationRoundStillRunning.selector);
        office.startValidationRound(1);
    }

    function testStartValidationRoundNotEnoughValidators() public {
        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        uint256[] memory betIds;
        _mockProposalToBeValidated(1, betIds, currentTimestamp - 100);

        vm.expectRevert(NotEnoughValidators.selector);
        office.startValidationRound(1);
    }

    function testValidateNotValidator() public {
        _mockValidators(100);
        address someone = address(200);

        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        uint256[] memory betIds = new uint256[](1);
        betIds[0] = 1;
        _mockProposalToBeValidated(1, betIds, currentTimestamp - 100);
        office.startValidationRound(1);

        vm.expectRevert(Unauthorized.selector);
        vm.prank(someone);
        office.validate(betIds);
    }

    function testValidateInvalidBetId() public {
        address[] memory validators = _mockValidators(100);

        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        uint256[] memory p1BetIds = new uint256[](1);
        p1BetIds[0] = 1;
        uint256[] memory p2BetIds = new uint256[](1);
        p2BetIds[0] = 2;
        _mockProposalToBeValidated(1, p1BetIds, currentTimestamp - 100);
        _mockProposalToBeValidated(2, p2BetIds, currentTimestamp - 100);

        office.startValidationRound(1);

        address[] memory p1Validators = _getValidatorsForProposalId(
            validators,
            1
        );

        vm.prank(p1Validators[0]);
        uint256[] memory validatorBetIds = new uint256[](2);
        validatorBetIds[0] = 1;
        validatorBetIds[1] = 2;
        vm.expectRevert(InvalidBetId.selector);
        office.validate(validatorBetIds);
    }

    function testValidateNotPickedValidator() public {
        address[] memory validators = _mockValidators(100);
        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        address notPickedValidator;
        uint256[] memory betIds = new uint256[](1);
        betIds[0] = 1;
        _mockProposalToBeValidated(1, betIds, currentTimestamp - 100);
        office.startValidationRound(1);

        // get a validator that has not been picked for proposal id 1
        for (uint256 i = 0; i < validators.length; i++) {
            vm.prank(validators[i]);
            bool isPicked;
            uint256[] memory pendingValidations = office
                .getPendingProposalValidations();

            for (uint256 j = 0; j < pendingValidations.length; j++) {
                if (pendingValidations[j] == 1) {
                    isPicked = true;
                    break;
                }
            }

            if (!isPicked) {
                notPickedValidator = validators[i];
            }
        }

        vm.expectRevert(Unauthorized.selector);
        vm.prank(notPickedValidator);
        office.validate(betIds);
    }

    function testFinishValidationProcess() public {
        uint256 numberOfValidators = 20;
        uint256[] memory betIds = new uint256[](2);
        betIds[0] = 1;
        betIds[1] = 2;
        address[] memory validators = _mockValidators(numberOfValidators);

        uint256[] memory validBetIds = new uint256[](1);
        validBetIds[0] = 1;

        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        _mockProposalToBeValidated(1, betIds, block.timestamp - 100);

        for (uint256 i = 0; i < office.minimumConsecutiveConsensus() + 1; i++) {
            office.startValidationRound(1);
            address[] memory proposalValidators = _getValidatorsForProposalId(
                validators,
                1
            );

            assertEq(
                proposalValidators.length,
                _getRequiredNumberOfValidators(validators.length)
            );

            for (uint256 j = 0; j < proposalValidators.length; j++) {
                vm.prank(proposalValidators[j]);
                office.validate(validBetIds);
            }
        }

        assertEq(office.isWinner(1), true);
        assertEq(office.isWinner(2), false);
    }

    function testStartValidationRoundAfterFinished() public {
        uint256 numberOfValidators = 20;
        uint256[] memory betIds = new uint256[](1);
        betIds[0] = 1;
        address[] memory validators = _mockValidators(numberOfValidators);

        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        _mockProposalToBeValidated(1, betIds, block.timestamp - 100);

        for (uint256 i = 0; i < office.minimumConsecutiveConsensus() + 1; i++) {
            office.startValidationRound(1);
            address[] memory proposalValidators = _getValidatorsForProposalId(
                validators,
                1
            );

            for (uint256 j = 0; j < proposalValidators.length; j++) {
                vm.prank(proposalValidators[j]);
                office.validate(betIds);
            }
        }

        vm.expectRevert(ProposalAlreadyValidated.selector);
        office.startValidationRound(1);
    }

    function testStartValidationRoundLimitReach() public {
        uint256 numberOfValidators = 20;
        uint256[] memory betIds = new uint256[](2);
        betIds[0] = 1;
        betIds[1] = 2;
        address[] memory validators = _mockValidators(numberOfValidators);

        uint256 currentTimestamp = 1000;
        vm.warp(currentTimestamp);

        _mockProposalToBeValidated(1, betIds, block.timestamp - 100);

        for (uint256 i = 0; i < office.maximumValidationRounds() + 1; i++) {
            office.startValidationRound(1);
            address[] memory proposalValidators = _getValidatorsForProposalId(
                validators,
                1
            );

            for (uint256 j = 0; j < proposalValidators.length; j++) {
                vm.prank(proposalValidators[j]);
                uint256[] memory validBetIds = new uint256[](1);
                validBetIds[0] = (j % 2) + 1;
                office.validate(validBetIds);
            }
        }

        assertEq(office.isUnconsensual(1), true);
    }

    function _getValidatorsForProposalId(
        address[] memory validators,
        uint256 proposalId
    ) internal returns (address[] memory proposalValidators) {
        proposalValidators = new address[](
            _getRequiredNumberOfValidators(validators.length)
        );

        uint256 counter = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            vm.prank(validators[i]);
            uint256[] memory pendingValidations = office
                .getPendingProposalValidations();

            for (uint256 j = 0; j < pendingValidations.length; j++) {
                if (pendingValidations[j] == proposalId) {
                    proposalValidators[counter] = validators[i];
                    counter++;
                }
            }
        }
    }

    function _mockProposalAlreadyValidated(uint256 id, uint256[] memory betIds)
        internal
    {
        _mockProposal(id, block.timestamp, block.timestamp, true, betIds);
    }

    function _mockProposalToBeValidated(
        uint256 id,
        uint256[] memory betIds,
        uint256 readyForValidationAt
    ) internal {
        _mockProposal(
            id,
            readyForValidationAt,
            readyForValidationAt,
            false,
            betIds
        );
    }

    function _mockProposal(
        uint256 id,
        uint256 betsClosedAt,
        uint256 readyForValidationAt,
        bool validated,
        uint256[] memory betIds
    ) internal {
        DABets.Proposal memory proposal;
        proposal.id = id;
        proposal.betsClosedAt = betsClosedAt;
        proposal.readyForValidationAt = readyForValidationAt;
        proposal.validated = validated;

        if (proposal.readyForValidationAt <= block.timestamp && !validated) {
            proposalsToBeValidated.push(proposal);
        }

        vm.mockCall(
            address(betsMock),
            abi.encodeWithSelector(DABets.getProposal.selector, id),
            abi.encode(proposal)
        );

        vm.mockCall(
            address(betsMock),
            abi.encodeWithSelector(DABets.getProposalsToBeValidated.selector),
            abi.encode(proposalsToBeValidated)
        );

        for (uint256 i = 0; i < betIds.length; i++) {
            vm.mockCall(
                address(betsMock),
                abi.encodeWithSelector(
                    DABets.getProposalByBetId.selector,
                    betIds[i]
                ),
                abi.encode(proposal)
            );
        }
    }

    function _getRequiredNumberOfValidators(uint256 totalValidators)
        internal
        view
        returns (uint256)
    {
        return
            (totalValidators * office.validatorsPercentagePerRound()) / 100 + 1;
    }

    function _mockProposal(
        uint256 id,
        uint256[] memory betIds,
        uint256 readyForValidationAt
    ) public {
        DABets.Proposal memory proposal;
        proposal.id = id;
        proposal.readyForValidationAt = readyForValidationAt;

        vm.mockCall(
            address(betsMock),
            abi.encodeWithSelector(DABets.getProposal.selector, id),
            abi.encode(proposal)
        );

        for (uint256 i = 0; i < betIds.length; i++) {
            vm.mockCall(
                address(betsMock),
                abi.encodeWithSelector(
                    DABets.getProposalByBetId.selector,
                    betIds[i]
                ),
                abi.encode(proposal)
            );
        }
    }

    function _mockValidators(uint256 numberOfValidators)
        internal
        returns (address[] memory validators)
    {
        validators = new address[](numberOfValidators);
        uint256 initialAddress = 20;

        for (uint256 i = 0; i < numberOfValidators; i++) {
            uint256 a = initialAddress + i;
            validators[i] = address(uint160(a));

            vm.mockCall(
                address(dabvMock),
                abi.encodeWithSelector(ERC20.balanceOf.selector, validators[i]),
                abi.encode(1)
            );
        }

        vm.mockCall(
            address(dabvMock),
            abi.encodeWithSelector(DABV.getOwners.selector),
            abi.encode(validators)
        );

        return validators;
    }
}
