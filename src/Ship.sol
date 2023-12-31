// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import "@openzeppelin/access/Ownable.sol";

contract Ship is Ownable {
    enum CARDINAL_DIRECTIONS {
        NORTH,
        EAST,
        SOUTH,
        WEST
    }

    string public constant VERSION = "0.1.2";
    uint256 public constant MAX_X_COORDINATE = 100;
    uint256 public constant MAX_Y_COORDINATE = 100;
    uint256 public constant HARBOR_MIN_X_COORDINATE = 80;
    uint256 public constant HARBOR_MAX_X_COORDINATE = 85;
    uint256 public constant HARBOR_MIN_Y_COORDINATE = 80;
    uint256 public constant HARBOR_MAX_Y_COORDINATE = 85;
    uint256 public constant TREASURE_X_COORDINATE = 42;
    uint256 public constant TREASURE_Y_COORDINATE = 69;
    uint256 public constant ALLOWED_TREASURE_CLAIM_FREQUENCY = 1 days;

    uint256 public immutable initXCoordinate;
    uint256 public immutable initYCoordinate;
    CARDINAL_DIRECTIONS public immutable initFacing;

    CARDINAL_DIRECTIONS public currentlyFacing;
    uint256 public currentXCoordinate;
    uint256 public currentYCoordinate;
    uint256 public lastClaimedTreasureTimestamp;

    uint256 public numberOfTimesHit;
    uint256 public numberOfHitsDealt;
    uint256 public treasureAmt;

    error AttackerDoesNotHaveIdenticalBytecode();
    error CannotGoAnyFurtherOnXAxis();
    error CannotGoAnyFurtherOnYAxis();
    error TargetDoesNotHaveIdenticalBytecode();
    error MustFireToTheSide(CARDINAL_DIRECTIONS facing, CARDINAL_DIRECTIONS attemptedAttackDirection);
    error TargetMustBeNextToYouInFiringDirection(
        CARDINAL_DIRECTIONS direction, uint256 currentRelevantCoordinate, uint256 targetsCurrentRelevantCoordinate
    );
    error TargetIsSafeFromAttack();
    error MustBeAtTreasureToLoot();
    error MustWaitUntilNextClaim(uint256 secondsToWait);

    constructor(uint256 initXCoordinate_, uint256 initYCoordinate_, CARDINAL_DIRECTIONS initFacing_)
        Ownable(msg.sender)
    {
        initXCoordinate = initXCoordinate_;
        initYCoordinate = initYCoordinate_;
        initFacing = initFacing_;
    }

    function isSafe() public view returns (bool) {
        return (
            ((currentXCoordinate >= HARBOR_MIN_X_COORDINATE) && (currentXCoordinate >= HARBOR_MAX_X_COORDINATE))
                && ((currentYCoordinate >= HARBOR_MIN_Y_COORDINATE) && (currentYCoordinate >= HARBOR_MAX_Y_COORDINATE))
        );
    }

    function pivot(CARDINAL_DIRECTIONS direction) public onlyOwner {
        currentlyFacing = direction;
    }

    function move() public onlyOwner {
        if (currentlyFacing == CARDINAL_DIRECTIONS.NORTH) {
            if (currentYCoordinate == MAX_Y_COORDINATE) revert CannotGoAnyFurtherOnYAxis();
            currentYCoordinate++;
        } else if (currentlyFacing == CARDINAL_DIRECTIONS.EAST) {
            if (currentXCoordinate == MAX_X_COORDINATE) revert CannotGoAnyFurtherOnXAxis();
            currentXCoordinate++;
        } else if (currentlyFacing == CARDINAL_DIRECTIONS.SOUTH) {
            if (currentYCoordinate == 0) revert CannotGoAnyFurtherOnYAxis();
            currentYCoordinate--;
        } else if (currentlyFacing == CARDINAL_DIRECTIONS.WEST) {
            if (currentXCoordinate == 0) revert CannotGoAnyFurtherOnYAxis();
            currentXCoordinate--;
        }
    }

    function lootTreasure() public onlyOwner {
        if ((currentXCoordinate != TREASURE_X_COORDINATE) && (currentYCoordinate != TREASURE_Y_COORDINATE)) {
            revert MustBeAtTreasureToLoot();
        }
        if (block.timestamp - ALLOWED_TREASURE_CLAIM_FREQUENCY < lastClaimedTreasureTimestamp) {
            revert MustWaitUntilNextClaim(
                lastClaimedTreasureTimestamp - (block.timestamp - ALLOWED_TREASURE_CLAIM_FREQUENCY)
            );
        }

        treasureAmt++;
        lastClaimedTreasureTimestamp = block.timestamp;
    }

    function fire(CARDINAL_DIRECTIONS direction, Ship target) public onlyOwner {
        if (address(target).codehash != address(this).codehash) revert TargetDoesNotHaveIdenticalBytecode();
        if ((currentlyFacing == CARDINAL_DIRECTIONS.NORTH) || (currentlyFacing == CARDINAL_DIRECTIONS.SOUTH)) {
            if ((direction == CARDINAL_DIRECTIONS.NORTH) || (direction == CARDINAL_DIRECTIONS.SOUTH)) {
                revert MustFireToTheSide(currentlyFacing, direction);
            }
            if (direction == CARDINAL_DIRECTIONS.EAST) {
                if (target.currentXCoordinate() != currentXCoordinate + 1) {
                    revert TargetMustBeNextToYouInFiringDirection(
                        direction, currentXCoordinate, target.currentXCoordinate()
                    );
                }
            } else {
                if (target.currentXCoordinate() != currentXCoordinate - 1) {
                    revert TargetMustBeNextToYouInFiringDirection(
                        direction, currentXCoordinate, target.currentXCoordinate()
                    );
                }
            }
        } else {
            // Either facing to the east or the west
            if ((direction == CARDINAL_DIRECTIONS.EAST) || (direction == CARDINAL_DIRECTIONS.WEST)) {
                revert MustFireToTheSide(currentlyFacing, direction);
            }
            if (direction == CARDINAL_DIRECTIONS.NORTH) {
                if (target.currentYCoordinate() != currentYCoordinate + 1) {
                    revert TargetMustBeNextToYouInFiringDirection(
                        direction, currentYCoordinate, target.currentYCoordinate()
                    );
                }
            } else {
                if (target.currentYCoordinate() != currentYCoordinate - 1) {
                    revert TargetMustBeNextToYouInFiringDirection(
                        direction, currentYCoordinate, target.currentYCoordinate()
                    );
                }
            }
        }

        numberOfHitsDealt++;

        target.hit();
    }

    function hit() external {
        if (address(msg.sender).codehash != address(this).codehash) revert AttackerDoesNotHaveIdenticalBytecode();
        if (isSafe()) revert TargetIsSafeFromAttack();
        numberOfTimesHit++;
    }
}
