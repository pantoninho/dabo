// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DAIM} from "./DAIM.sol";
import {DAIMarkets} from "./DAIMarkets.sol";
import {FACTx} from "./FACTx.sol";
import "./Errors.sol";

/**
 * @author  0xerife
 * @title   DAIM Office
 * @notice  TODO: write this
 */
contract DAIOffice {
    event AssigningValidators(uint256 validatorsLength);
    event PickedValidator(address validator, uint256 validatorWeight);
    // a validation represents a bet(s) chosen as correct by validators for a specific proposal.
    // if two validators select the same bet as correct, both will contribute to the same validation weight
    struct ProposalValidation {
        uint256[] validBetIds; // the valid betIds aka the correct answer
        bool unverifiable; // if the proposal is unverifiable. this boolean takes precedence over validBetIds. if this boolean is true, means the validator did not have means to validate the proposal
        uint256 weight; // the weight of the validation. validations' weights are used to measure amount of consensus
    }

    // a round represents a round of validations by the validators
    // each round produces one or more proposal validations
    struct ValidationRound {
        address[] validators;
        uint256 totalWeight;
    }

    // a validation process represents a set of validation rounds
    // there needs to be multiple consecutive consensus for the process to complete successfully
    struct ValidationProcess {
        bool validated;
        uint256 currentRound;
        uint256 consecutiveConsensus;
    }

    struct Veredictum {
        uint256[] validBetIds;
        bool unverifiable;
        bool noConsensus;
    }

    uint256 private constant minMajorityWeightPercentage = 90;
    uint256 private constant minValidators = 1;
    uint256 public constant validatorsPercentagePerRound = 100;
    uint256 public constant minimumConsecutiveConsensus = 3;
    uint256 public constant maximumValidationRounds = 50;

    DAIM daim;

    uint256[] activeValidationProcesses;
    // proposal id => Validation Process
    mapping(uint256 => ValidationProcess) validationProcesses;
    // proposal id => Veredictum
    mapping(uint256 => Veredictum) veredictums;
    // round id => validation round
    mapping(uint256 => ValidationRound) validationRounds;
    // round id => address => weight
    mapping(uint256 => mapping(address => uint256)) validatorsByRound;
    // address => number of pending validations
    mapping(address => uint256) pendingValidationsByValidator;
    // validation round id => proposal validation ids
    mapping(uint256 => uint256[]) validationsByRound;
    // validation id => ProposalValidation
    mapping(uint256 => ProposalValidation) validations;

    constructor(DAIM _daim) {
        daim = _daim;
    }

    function startValidationRound(uint256 proposalId) external {
        ValidationProcess storage process = validationProcesses[proposalId];

        if (process.validated) {
            revert ProposalAlreadyValidated();
        }

        if (
            process.currentRound > 0 &&
            !_isRoundClosed(_getCurrentRoundId(proposalId))
        ) {
            revert CurrentValidationRoundStillRunning();
        }

        if (process.currentRound == 0) {
            activeValidationProcesses.push(proposalId);
        } else {
            _updateConsensus(proposalId);
        }

        if (_consecutiveConsensusReached(proposalId)) {
            process.validated = true;
            (
                ,
                uint256[] memory validBetIds,
                bool unverifiable
            ) = _getRoundConsensus(_getCurrentRoundId(proposalId));

            veredictums[proposalId].validBetIds = validBetIds;
            veredictums[proposalId].unverifiable = unverifiable;
            bets().removeActiveProposal(proposalId);
            return;
        }

        if (_roundLimitReached(proposalId)) {
            process.validated = true;
            veredictums[proposalId].noConsensus = true;
            return;
        }

        process.currentRound++;
        _assignValidators(proposalId);
    }

    function validate(uint256[] memory betIds) external onlyValidators {
        DAIMarkets.Proposal memory proposal = bets().getProposalByBetId(
            betIds[0]
        );

        if (!_isValidatorOf(msg.sender, proposal.id)) {
            revert Unauthorized();
        }

        for (uint256 i = 1; i < betIds.length; i++) {
            if (proposal.id != bets().getProposalByBetId(betIds[i]).id) {
                revert InvalidBetId();
            }
        }

        _validate(msg.sender, proposal.id, betIds, false);
    }

    function markAsUnverifiable(uint256 proposalId) external onlyValidators {
        uint256[] memory validBetIds;

        if (!_isValidatorOf(msg.sender, proposalId)) {
            revert Unauthorized();
        }

        _validate(msg.sender, proposalId, validBetIds, true);
    }

    function getPendingProposalValidations()
        external
        view
        returns (uint256[] memory pendingValidations)
    {
        return _getPendingProposalValidations(msg.sender);
    }

    function getProcessById(uint256 id)
        external
        view
        returns (ValidationProcess memory process)
    {
        process = validationProcesses[id];
    }

    function isWinner(uint256 betId) external view returns (bool) {
        DAIMarkets.Proposal memory proposal = bets().getProposalByBetId(betId);

        if (!validationProcesses[proposal.id].validated) {
            return false;
        }

        uint256[] memory validBetIds = veredictums[proposal.id].validBetIds;

        for (uint256 i = 0; i < validBetIds.length; i++) {
            if (validBetIds[i] == betId) {
                return true;
            }
        }

        return false;
    }

    function isUnconsensual(uint256 proposalId) external view returns (bool) {
        if (!validationProcesses[proposalId].validated) {
            return false;
        }

        return veredictums[proposalId].noConsensus;
    }

    function isProcessActive(uint256 proposalId) external view returns (bool) {
        if (validationProcesses[proposalId].currentRound == 0) {
            return false;
        }

        return !_isRoundClosed(_getCurrentRoundId(proposalId));
    }

    function getRoundValidators(uint256 proposalId, uint256 roundIndex)
        external
        view
        returns (address[] memory)
    {
        return validationRounds[_getRoundId(proposalId, roundIndex)].validators;
    }

    function _isValidatorOf(address validator, uint256 proposalId)
        internal
        view
        returns (bool isValidator)
    {
        return validatorsByRound[_getCurrentRoundId(proposalId)][validator] > 0;
    }

    function _getPendingProposalValidations(address validator)
        internal
        view
        returns (uint256[] memory pendingValidations)
    {
        uint256 counter = 0;

        pendingValidations = new uint256[](
            pendingValidationsByValidator[validator]
        );

        for (uint256 i = 0; i < activeValidationProcesses.length; i++) {
            if (_isValidatorOf(validator, activeValidationProcesses[i])) {
                pendingValidations[counter] = activeValidationProcesses[i];
                counter++;
            }
        }
    }

    function _validate(
        address validator,
        uint256 proposalId,
        uint256[] memory validBetIds,
        bool unverifiable
    ) internal {
        // get associated validation process and round
        ValidationProcess storage process = validationProcesses[proposalId];
        uint256 roundId = _getRoundId(proposalId, process.currentRound);

        // get validation id
        uint256 validationId = _getValidationId(
            roundId,
            validBetIds,
            unverifiable
        );

        uint256 validatorWeight = validatorsByRound[roundId][validator];

        // if it's the first time this bet is selected as the correct answer, create a new validation
        if (validations[validationId].weight == 0) {
            validations[validationId].validBetIds = validBetIds;
            validations[validationId].unverifiable = unverifiable;
            validations[validationId].weight = validatorWeight;
            validationsByRound[roundId].push(validationId);
        } else {
            // if validation already exists. increment weight with user amount of FACTx
            validations[validationId].weight += validatorWeight;
        }

        pendingValidationsByValidator[validator]--;
    }

    function _assignValidators(uint256 proposalId) internal {
        uint256 currentRoundId = _getCurrentRoundId(proposalId);

        address[] memory validators = factx().getOwners();
        emit AssigningValidators(validators.length);

        if (validators.length == 0) {
            return;
        }

        uint256 requiredValidators = _getRequiredNumberOfRoundValidators(
            validators.length
        );

        ValidationRound storage currentRound = validationRounds[currentRoundId];
        // fisher-yates shuffle
        for (uint256 i = 0; i < requiredValidators; i++) {
            uint256 random = _getRandomNumber(validators.length - i);
            address pickedValidator = validators[random];
            validators[random] = validators[validators.length - (i + 1)];

            currentRound.validators.push(pickedValidator);
            pendingValidationsByValidator[pickedValidator]++;

            uint256 validatorWeight = factx().balanceOf(pickedValidator);
            emit PickedValidator(pickedValidator, validatorWeight);
            currentRound.totalWeight += validatorWeight;
            validatorsByRound[currentRoundId][
                pickedValidator
            ] = validatorWeight;
        }
    }

    function _getRandomNumber(uint256 max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(max, block.timestamp))) % max;
    }

    function _getRequiredNumberOfRoundValidators(uint256 totalValidators)
        internal
        pure
        returns (uint256)
    {
        return (totalValidators * validatorsPercentagePerRound + 1) / 100;
    }

    function _roundLimitReached(uint256 proposalId)
        internal
        view
        returns (bool roundLimitReached)
    {
        return
            validationProcesses[proposalId].currentRound >=
            maximumValidationRounds;
    }

    function _consecutiveConsensusReached(uint256 proposalId)
        internal
        view
        returns (bool consecutiveConsensusReached)
    {
        return
            validationProcesses[proposalId].consecutiveConsensus >=
            minimumConsecutiveConsensus;
    }

    function _getCurrentRoundId(uint256 proposalId)
        internal
        view
        returns (uint256 roundId)
    {
        ValidationProcess storage process = validationProcesses[proposalId];
        roundId = _getRoundId(proposalId, process.currentRound);
    }

    function _getRoundId(uint256 proposalId, uint256 roundIndex)
        internal
        pure
        returns (uint256 roundId)
    {
        if (roundIndex == 0) {
            revert ValidationNotStarted();
        }
        return uint256(keccak256(abi.encodePacked(proposalId, roundIndex)));
    }

    function _getValidationId(
        uint256 roundId,
        uint256[] memory betIds,
        bool unverifiable
    ) internal pure returns (uint256 validationId) {
        return
            uint256(keccak256(abi.encodePacked(roundId, betIds, unverifiable)));
    }

    function _isRoundClosed(uint256 roundId)
        internal
        view
        returns (bool isClosed)
    {
        uint256[] memory validationIds = validationsByRound[roundId];
        uint256 validationsWeight = 0;

        for (uint256 i = 0; i < validationIds.length; i++) {
            validationsWeight += validations[validationIds[i]].weight;
        }

        return validationsWeight >= validationRounds[roundId].totalWeight;
    }

    function _getRoundConsensus(uint256 roundId)
        internal
        view
        returns (
            bool consensus,
            uint256[] memory validBetIds,
            bool unverifiable
        )
    {
        uint256[] memory validationIds = validationsByRound[roundId];

        uint256 majorityWeight = 0;
        for (uint256 i = 0; i < validationIds.length; i++) {
            if (validations[validationIds[i]].weight <= majorityWeight) {
                continue;
            }

            majorityWeight = validations[validationIds[i]].weight;
            validBetIds = validations[validationIds[i]].validBetIds;
            unverifiable = validations[validationIds[i]].unverifiable;
        }

        consensus =
            (majorityWeight * 100) / validationRounds[roundId].totalWeight >=
            minMajorityWeightPercentage;
    }

    function _updateConsensus(uint256 proposalId) internal {
        // todo: check if current round is closed
        ValidationProcess storage process = validationProcesses[proposalId];
        uint256 currentRoundId = _getCurrentRoundId(proposalId);

        (
            bool currentRoundConsensus,
            uint256[] memory currentRoundValidBetIds,
            bool currentRoundUnverifiable
        ) = _getRoundConsensus(currentRoundId);

        if (process.currentRound == 1) {
            process.consecutiveConsensus = currentRoundConsensus ? 1 : 0;
            return;
        }

        uint256 previousRoundId = _getRoundId(
            proposalId,
            process.currentRound - 1
        );

        (
            bool previousRoundConsensus,
            uint256[] memory previousRoundValidBetIds,
            bool previousRoundUnverifiable
        ) = _getRoundConsensus(previousRoundId);

        // if one of the rounds has not reached consensus, this is not a matching consensus for sure
        if (!currentRoundConsensus || !previousRoundConsensus) {
            process.consecutiveConsensus = 0;
            return;
        }

        // if both matches reached consensus on the "unverifiability" of the proposal, its a matching consensus
        if (
            currentRoundUnverifiable == true ||
            previousRoundUnverifiable == true
        ) {
            process.consecutiveConsensus += 1;
            return;
        }

        // if both round validations are equal, its a matching consensus
        if (
            _areEqualValidations(
                currentRoundValidBetIds,
                previousRoundValidBetIds
            )
        ) {
            process.consecutiveConsensus += 1;
            return;
        }

        // every other case is not a matching consensus
        process.consecutiveConsensus = 0;
    }

    function _areEqualValidations(
        uint256[] memory v1BetIds,
        uint256[] memory v2BetIds
    ) internal pure returns (bool areEqual) {
        return
            keccak256(abi.encodePacked(v1BetIds)) ==
            keccak256(abi.encodePacked(v2BetIds));
    }

    function bets() internal view returns (DAIMarkets) {
        return daim.bets();
    }

    function factx() internal view returns (FACTx) {
        return daim.factx();
    }

    modifier onlyValidators() {
        if (factx().balanceOf(msg.sender) == 0) {
            revert Unauthorized();
        }
        _;
    }

    modifier ensureReadyForValidation(uint256 proposalId) {
        if (
            bets().getProposal(proposalId).readyForValidationAt >
            block.timestamp
        ) {
            revert ProposalNotReadyForValidation();
        }
        _;
    }

    modifier ensureEnoughValidators() {
        if (factx().getOwners().length < minValidators) {
            revert NotEnoughValidators();
        }
        _;
    }
}
