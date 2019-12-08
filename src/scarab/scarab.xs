// Scarab
// Created 08/12/2019
// Based on Jotunheim

include "MmM_FE_lib.xs";
include "cof89_lib.xs";

void main(void) {

	// Loading Status
	loadStatus(0.01);

	/* **************************** */
	/* Section 1 Map Initialization */
	/* **************************** */

	// Initialise Map
	int mapSizeMultiplier = initMap();

	// Default Terrain
	rmTerrainInitialize("cliffEgyptianA", 12.0);
	rmSetSeaLevel(0.0);

	// Set Lighting
	rmSetLightingSet("anatolia");

	// Loading Status
	loadStatus(0.07);

	/* ***************** */
	/* Section 2 Classes */
	/* ***************** */

	int classForest = rmDefineClass("forest");
	int classPlayer = rmDefineClass("player");
	int classStartingSettlement = rmDefineClass("starting settlement");
	int connectionClass = rmDefineClass("connection");
	int patchClass = rmDefineClass("patchClass");
	int teamClass = rmDefineClass("teamClass");

	// Loading Status
	loadStatus(0.13);

	/* **************************** */
	/* Section 3 Global Constraints */
	/* **************************** */

	// Create Contraints
	int playerConstraint = rmCreateClassDistanceConstraint("stay away from players", classPlayer, 10.0);
	int shortAvoidImpassableLand = rmCreateTerrainDistanceConstraint("short avoid impassable land", "land", false, 6.0);

	// Loading Status
	loadStatus(0.20);

	/* ********************* */
	/* Section 4 Map Outline */
	/* ********************* */

	// Mountain Width
	int baseMountainWidth = 30;
	int connectionWidth = 30;
	if(cNumberTeams > 2) {
		baseMountainWidth = 20;
		connectionWidth = 25;
	}
	int teamConstraint = rmCreateClassDistanceConstraint("how wide the mountain is", teamClass, baseMountainWidth);

	// Main Connection
	int connectionID = rmCreateConnection("passes");
	rmAddConnectionTerrainReplacement(connectionID, "cliffEgyptianA", "SandA");
	rmAddConnectionTerrainReplacement(connectionID, "cliffEgyptianB", "SandA");
	rmSetConnectionType(connectionID, cConnectAreas, false, 1.0);
	rmSetConnectionWarnFailure(connectionID, false);
	rmSetConnectionWidth(connectionID, connectionWidth, 4);
	rmSetConnectionTerrainCost(connectionID, "cliffEgyptianA", 5.0);
	rmSetConnectionTerrainCost(connectionID, "cliffEgyptianB", 3.0);
	rmSetConnectionPositionVariance(connectionID, 0.3);
	rmSetConnectionBaseHeight(connectionID, 0.0);
	rmSetConnectionHeightBlend(connectionID, 2);
	rmAddConnectionToClass(connectionID, connectionClass);

	// Additional Connection
	int secondConnectionExists = 0;
	float secondConnectionChance = rmRandFloat(0.0, 1.0);
	if(cNumberTeams < 3) {
		if(cNumberNonGaiaPlayers < 4) {
			if(secondConnectionChance < 0.8) {
				secondConnectionExists = 1;
			}
		}
		else {
			if(secondConnectionChance < 0.6) {
				secondConnectionExists = 1;
			}
		}
	}
	rmEchoInfo("secondConnectionChance " + secondConnectionChance + "secondConnectionExists " + secondConnectionExists);
	int connectionEdgeConstraint = rmCreateBoxConstraint("connections avoid edge of map", rmXTilesToFraction(16), rmZTilesToFraction(16), 1.0 - rmXTilesToFraction(16), 1.0 - rmZTilesToFraction(16));
	if(secondConnectionExists == 1) {
		int alternateConnection = rmCreateConnection("alternate passes");
		rmAddConnectionTerrainReplacement(alternateConnection, "cliffEgyptianA", "SandA");
		rmAddConnectionTerrainReplacement(alternateConnection, "cliffEgyptianB", "SandA");
		rmSetConnectionType(alternateConnection, cConnectAreas, false, 1.0);
		rmSetConnectionWarnFailure(alternateConnection, false);
		rmSetConnectionWidth(alternateConnection, connectionWidth, 4);
		rmSetConnectionTerrainCost(alternateConnection, "cliffEgyptianA", 5.0);
		rmSetConnectionTerrainCost(alternateConnection, "cliffEgyptianB", 3.0);
		rmAddConnectionStartConstraint(alternateConnection, connectionEdgeConstraint);
		rmAddConnectionEndConstraint(alternateConnection, connectionEdgeConstraint);
		rmAddConnectionStartConstraint(alternateConnection, playerConstraint);
		rmAddConnectionEndConstraint(alternateConnection, playerConstraint);
		rmSetConnectionPositionVariance(alternateConnection, -1.0);
		rmSetConnectionBaseHeight(alternateConnection, 0.0);
		rmSetConnectionHeightBlend(alternateConnection, 2);
		rmAddConnectionToClass(alternateConnection, connectionClass);
	}

	// Player Placement
	rmPlacePlayersCircular(0.30, 0.40, rmDegreesToRadians(4.0));
	rmRecordPlayerLocations();

	// Team Contraints
	int teamEdgeConstraint = rmCreateBoxConstraint("team edge of map", rmXTilesToFraction(4), rmZTilesToFraction(4), 1.0 - rmXTilesToFraction(4), 1.0 - rmZTilesToFraction(4));
	float teamPercentArea = 0.80 / cNumberTeams;
	if(cNumberNonGaiaPlayers < 4) {
		teamPercentArea = 0.75 / cNumberTeams;
	}
	float percentPerPlayer = 0.75 / cNumberNonGaiaPlayers;
	float teamSize = 0;
	for(x = 0; < cNumberTeams) {

		// Team Area
		int teamID = rmCreateArea("team" + x);
		rmSetTeamArea(x, teamID);
		teamSize = percentPerPlayer*rmGetNumberPlayersOnTeam(x);
		rmSetAreaSize(teamID, teamSize * 0.9, teamSize * 1.1);
		rmSetAreaWarnFailure(teamID, false);
		rmSetAreaTerrainType(teamID, "SandA");
		rmAddAreaTerrainLayer(teamID, "cliffEgyptianB", 2, 6);
		rmAddAreaTerrainLayer(teamID, "cliffEgyptianA", 0, 2);
		rmSetAreaMinBlobs(teamID, 1);
		rmSetAreaMaxBlobs(teamID, 5);
		rmSetAreaMinBlobDistance(teamID, 16.0);
		rmSetAreaMaxBlobDistance(teamID, 40.0);
		rmSetAreaCoherence(teamID, 0.0);
		rmSetAreaSmoothDistance(teamID, 10);
		rmAddAreaToClass(teamID, teamClass);
		rmSetAreaBaseHeight(teamID, 0.0);
		rmSetAreaHeightBlend(teamID, 2);
		rmAddAreaConstraint(teamID, teamConstraint);
		rmAddAreaConstraint(teamID, teamEdgeConstraint);
		rmSetAreaLocTeam(teamID, x);
		rmAddConnectionArea(connectionID, teamID);
		if(secondConnectionExists == 1.0) {
			rmAddConnectionArea(alternateConnection, teamID);
		}
		rmEchoInfo("Team area" + x);
	}

	// Patch Constraints
	int patchConstraint = rmCreateClassDistanceConstraint("patch vs patch", patchClass, 10);
	int failCount = 0;
	for(x = 0; < cNumberNonGaiaPlayers * 60 * mapSizeMultiplier) {
		int rockPatch = rmCreateArea("rock patch" + x);
		rmSetAreaSize(rockPatch, rmAreaTilesToFraction(50), rmAreaTilesToFraction(100));
		rmSetAreaWarnFailure(rockPatch, false);
		rmSetAreaBaseHeight(rockPatch, rmRandFloat(8.0, 10.0));
		rmSetAreaHeightBlend(rockPatch, 1);
		rmSetAreaTerrainType(rockPatch, "cliffEgyptianA");
		rmSetAreaMinBlobs(rockPatch, 1);
		rmSetAreaMaxBlobs(rockPatch, 3);
		rmSetAreaMinBlobDistance(rockPatch, 5.0);
		rmSetAreaMaxBlobDistance(rockPatch, 5.0 * mapSizeMultiplier);
		rmSetAreaCoherence(rockPatch, 0.3);
		if(rmBuildArea(rockPatch) == false) {
			failCount ++;
			if(failCount == 3 * mapSizeMultiplier) {
				break;
			}
		}
		else {
			failCount = 0;
		}
	}

	// Build Areas
	rmBuildAllAreas();
	rmBuildConnection(connectionID);
	if(secondConnectionExists == 1.0) {
		rmBuildConnection(alternateConnection);
	}

	// Loading Status
	loadStatus(0.26);

	/* ********************** */
	/* Section 5 Player Areas */
	/* ********************** */

	// Team Spacing
	rmSetTeamSpacingModifier(0.75);
	float playerFraction = rmAreaTilesToFraction(2500);

	// Player Areas
	for(x = 1; <cNumberPlayers) {
		int id = rmCreateArea("Player" + x, rmAreaID("team" + rmGetPlayerTeam(x)));
		rmEchoInfo("Player" + x + "team" + rmGetPlayerTeam(x));
		rmSetPlayerArea(x, id);
		rmSetAreaSize(id, 0.9 * playerFraction, 1.1 * playerFraction);
		rmAddAreaToClass(id, classPlayer);
		rmSetAreaWarnFailure(id, false);
		rmSetAreaMinBlobs(id, 1 * mapSizeMultiplier);
		rmSetAreaMaxBlobs(id, 5 * mapSizeMultiplier);
		rmSetAreaMinBlobDistance(id, 16.0);
		rmSetAreaMaxBlobDistance(id, 40.0 * mapSizeMultiplier);
		rmSetAreaCoherence(id, 0.0);
		rmAddAreaConstraint(id, playerConstraint);
		rmAddAreaConstraint(id, shortAvoidImpassableLand);
		rmSetAreaLocPlayer(id, x);
		rmSetAreaTerrainType(id, "SandC");
		rmAddAreaTerrainLayer(id, "SandC", 4, 12);
		rmAddAreaTerrainLayer(id, "SandA", 0, 4);
	}
	rmBuildAllAreas();

	// Loading Status
	loadStatus(0.33);

	/* *********************** */
	/* Section 6 Map Specifics */
	/* *********************** */

	// SandB Patches
	for(x = 1; < cNumberPlayers) {
		for(y = 0; < 3 * mapSizeMultiplier) {
			int id3 = rmCreateArea("sand b patch" + x + y, rmAreaID("player" + x));
			rmSetAreaSize(id3, rmAreaTilesToFraction(10 * mapSizeMultiplier), rmAreaTilesToFraction(80 * mapSizeMultiplier));
			rmSetAreaWarnFailure(id3, false);
			rmSetAreaTerrainType(id3, "SandB");
			rmAddAreaConstraint(id3, shortAvoidImpassableLand);
			rmSetAreaMinBlobs(id3, 1 * mapSizeMultiplier);
			rmSetAreaMaxBlobs(id3, 5 * mapSizeMultiplier);
			rmSetAreaMinBlobDistance(id3, 5.0);
			rmSetAreaMaxBlobDistance(id3, 20.0 * mapSizeMultiplier);
			rmSetAreaCoherence(id3, 0.0);
			rmBuildArea(id3);
		}
	}

	// SandC Patches
	for(x = 1; < cNumberPlayers) {
		for(y = 0; < 3 * mapSizeMultiplier) {
			int id2 = rmCreateArea("sand c patch" + x + y, rmAreaID("player" + x));
			rmSetAreaSize(id2, rmAreaTilesToFraction(400 * mapSizeMultiplier), rmAreaTilesToFraction(600 * mapSizeMultiplier));
			rmSetAreaWarnFailure(id2, false);
			rmSetAreaTerrainType(id2, "SandC");
			rmAddAreaTerrainLayer(id2, "SandC", 0, 2);
			rmAddAreaConstraint(id2, shortAvoidImpassableLand);
			rmSetAreaMinBlobs(id2, 1 * mapSizeMultiplier);
			rmSetAreaMaxBlobs(id2, 5 * mapSizeMultiplier);
			rmSetAreaMinBlobDistance(id2, 5.0);
			rmSetAreaMaxBlobDistance(id2, 20.0 * mapSizeMultiplier);
			rmSetAreaCoherence(id2, 0.0);
			rmBuildArea(id2);
		}
	}

	// Create Wrinkles
	int numTries = 10 * cNumberNonGaiaPlayers;
	int avoidBuildings = rmCreateTypeDistanceConstraint("avoid buildings", "Building", 20.0);
	failCount = 0;
	for(x = 0; < numTries) {
		int elevID = rmCreateArea("wrinkle" + x);
		rmSetAreaSize(elevID, rmAreaTilesToFraction(15), rmAreaTilesToFraction(120));
		rmSetAreaWarnFailure(elevID, false);
		rmSetAreaBaseHeight(elevID, rmRandFloat(1.0, 3.0));
		rmSetAreaHeightBlend(elevID, 1);
		rmSetAreaMinBlobs(elevID, 1);
		rmSetAreaMaxBlobs(elevID, 3);
		rmSetAreaMinBlobDistance(elevID, 16.0);
		rmSetAreaMaxBlobDistance(elevID, 20.0);
		rmSetAreaCoherence(elevID, 0.0);
		rmAddAreaConstraint(elevID, avoidBuildings);
		rmAddAreaConstraint(elevID, shortAvoidImpassableLand);
		if(rmBuildArea(elevID) == false) {
			failCount ++;
			if(failCount == 10) {
				break;
			}
		}
		else {
			failCount = 0;
		}
	}
	failCount = 0;

	// Loading Status
	loadStatus(0.40);

	/* **************************** */
	/* Section 7 Object Constraints */
	/* **************************** */

	// Create Contraints
	int avoidFood = rmCreateTypeDistanceConstraint("avoid food", "food", 15.0);
	int shortAvoidSettlement = rmCreateTypeDistanceConstraint("short avoid settlement", "AbstractSettlement", 10.0);
	int farStartingSettleConstraint = rmCreateClassDistanceConstraint("objects avoid player TCs", rmClassID("starting settlement"), 40.0);
	int avoidGold = rmCreateTypeDistanceConstraint("avoid gold", "gold", 30.0);
	int goldAvoidsGold = rmCreateTypeDistanceConstraint("gold avoid gold", "gold", 40.0);
	int forestObjConstraint = rmCreateTypeDistanceConstraint("forest obj", "all", 6.0);

	// Loading Status
	loadStatus(0.46);

	/* ********************************* */
	/* Section 8 Fair Location Placement */
	/* ********************************* */

	// Gold Placement
	int startingGoldFairLocID = -1;
	if(rmRandFloat(0, 1) > 0.5) {
		startingGoldFairLocID = rmAddFairLoc("Starting Gold", true, false, 20, 21, 0, 15);
	}
	else {
		startingGoldFairLocID = rmAddFairLoc("Starting Gold", false, false, 20, 21, 0, 15);
	}
	if(rmPlaceFairLocs()) {
		int startingGoldID = rmCreateObjectDef("Starting Gold");
		rmAddObjectDefItem(startingGoldID, "Gold Mine Small", 1, 0.0);
		for(x = 1; < cNumberPlayers) {
			for(y = 0; < rmGetNumberFairLocs(x)) {
				rmPlaceObjectDefAtLoc(startingGoldID, x, rmFairLocXFraction(x, y), rmFairLocZFraction(x, y), 1);
			}
		}
	}
	rmResetFairLocs();

	// Starting Settlement
	int startingSettlementID = rmCreateObjectDef("starting settlement");
	rmAddObjectDefItem(startingSettlementID, "Settlement Level 1", 1, 0.0);
	rmAddObjectDefToClass(startingSettlementID, rmClassID("starting settlement"));
	rmSetObjectDefMinDistance(startingSettlementID, 0.0);
	rmSetObjectDefMaxDistance(startingSettlementID, 0.0);
	rmPlaceObjectDefPerPlayer(startingSettlementID, true);
	int closeID = -1;
	int farID = -1;
	int TCavoidSettlement = rmCreateTypeDistanceConstraint("TC avoid TC by long distance", "AbstractSettlement", 50.0);
	int TCavoidStart = rmCreateClassDistanceConstraint("TC avoid starting by long distance", classStartingSettlement, 50.0);
	int TCavoidWater = rmCreateTerrainDistanceConstraint("TC avoid water", "Water", true, 30.0);
	int TCavoidImpassableLand = rmCreateTerrainDistanceConstraint("TC avoid badlands", "land", false, 20.0);
	if(cNumberNonGaiaPlayers == 2) {
		for(p = 1; <= cNumberNonGaiaPlayers) {

			// Close Settlement
			id = rmAddFairLoc("Settlement", false, true, 60, 65, 40, 16);
			rmAddFairLocConstraint(id, TCavoidImpassableLand);
			rmAddFairLocConstraint(id, TCavoidSettlement);
			rmAddFairLocConstraint(id, TCavoidStart);
			if(rmPlaceFairLocs()) {
				id = rmCreateObjectDef("close settlement" + p);
				rmAddObjectDefItem(id, "Settlement", 1, 0.0);
				rmPlaceObjectDefAtLoc(id, p, rmFairLocXFraction(p, 0), rmFairLocZFraction(p, 0), 1);
				int settleArea = rmCreateArea("settlement area" + p, rmAreaID("Player" + p));
				rmSetAreaLocation(settleArea, rmFairLocXFraction(p, 0), rmFairLocZFraction(p, 0));
				rmSetAreaSize(settleArea, 0.01, 0.01);
				rmSetAreaTerrainType(settleArea, "SandC");
				rmAddAreaTerrainLayer(settleArea, "SandA", 0, 8);
				rmAddAreaTerrainLayer(settleArea, "SandC", 8, 16);
				rmAddAreaTerrainLayer(settleArea, "SandC", 16, 24);
				rmBuildArea(settleArea);
			}
			rmResetFairLocs();

			// Far Settlement
			id = rmAddFairLoc("Settlement", true, false, rmXFractionToMeters(0.29), rmXFractionToMeters(0.32), 40, 16);
			rmAddFairLocConstraint(id, TCavoidSettlement);
			rmAddFairLocConstraint(id, TCavoidImpassableLand);
			rmAddFairLocConstraint(id, TCavoidStart);
			rmAddFairLocConstraint(id, TCavoidWater);
			if(rmPlaceFairLocs()) {
				id = rmCreateObjectDef("far settlement" + p);
				rmAddObjectDefItem(id, "Settlement", 1, 0.0);
				rmPlaceObjectDefAtLoc(id, p, rmFairLocXFraction(p, 0), rmFairLocZFraction(p, 0), 1);
				int settlementArea = rmCreateArea("settlement_area_" + p);
				rmSetAreaLocation(settlementArea, rmFairLocXFraction(p, 0), rmFairLocZFraction(p, 0));
				rmSetAreaSize(settlementArea, 0.01, 0.01);
				rmSetAreaTerrainType(settlementArea, "SandC");
				rmAddAreaTerrainLayer(settlementArea, "SandA", 0, 8);
				rmAddAreaTerrainLayer(settlementArea, "SandC", 8, 16);
				rmAddAreaTerrainLayer(settlementArea, "SandC", 16, 24);
				rmBuildArea(settlementArea);
			}
			rmResetFairLocs();
		}
	}
	else {
		for(p = 1; <= cNumberNonGaiaPlayers) {

			// Close Settlement
			closeID = rmCreateObjectDef("close settlement"+p);
			rmAddObjectDefItem(closeID, "Settlement", 1, 0.0);
			rmAddObjectDefConstraint(closeID, TCavoidSettlement);
			rmAddObjectDefConstraint(closeID, TCavoidStart);
			rmAddObjectDefConstraint(closeID, TCavoidImpassableLand);
			for(attempt = 4; < 10) {
				rmPlaceObjectDefAtLoc(closeID, p, rmGetPlayerX(p), rmGetPlayerZ(p), 1);
				if(rmGetNumberUnitsPlaced(closeID) > 0) {
					break;
				}
				rmSetObjectDefMaxDistance(closeID, 10 * attempt);
			}

			// Far Settlement
			farID = rmCreateObjectDef("far settlement" + p);
			rmAddObjectDefItem(farID, "Settlement", 1, 0.0);
			rmAddObjectDefConstraint(farID, TCavoidImpassableLand);
			rmAddObjectDefConstraint(farID, TCavoidStart);
			rmAddObjectDefConstraint(farID, TCavoidSettlement);
			for(attempt = 6; < 15) {
				rmPlaceObjectDefAtLoc(farID, p, rmGetPlayerX(p), rmGetPlayerZ(p), 1);
				if(rmGetNumberUnitsPlaced(farID) > 0) {
					break;
				}
				rmSetObjectDefMaxDistance(farID, 10 * attempt);
			}
		}
	}
	rmResetFairLocs();

	// Repeat for Giant Map
	if(cMapSize == 2) {

		// Close FairLocs
		id = rmAddFairLoc("Settlement", false, true,  rmXFractionToMeters(0.3), rmXFractionToMeters(0.4), 70, 16);
		rmAddFairLocConstraint(id, TCavoidSettlement);
		rmAddFairLocConstraint(id, TCavoidStart);
		rmAddFairLocConstraint(id, TCavoidImpassableLand);
		id = rmAddFairLoc("Settlement", false, false,  rmXFractionToMeters(0.35), rmXFractionToMeters(0.4), 70, 16);
		rmAddFairLocConstraint(id, TCavoidSettlement);
		rmAddFairLocConstraint(id, TCavoidStart);
		rmAddFairLocConstraint(id, TCavoidImpassableLand);

		// Create Settlements
		if(rmPlaceFairLocs()) {
			for(p = 1; <= cNumberNonGaiaPlayers) {
				for(FL = 0; < 2) {
					id = rmCreateObjectDef("Giant settlement_" + p + "_" + FL);
					rmAddObjectDefItem(id, "Settlement", 1, 1.0);
					int settlementArea2 = rmCreateArea("other_settlement_area_" + p + "_" + FL);
					rmSetAreaLocation(settlementArea2, rmFairLocXFraction(p, FL), rmFairLocZFraction(p, FL));
					rmSetAreaSize(settlementArea2, 0.005, 0.005);
					rmSetAreaTerrainType(settlementArea2, "SandC");
					rmAddAreaTerrainLayer(settlementArea2, "SandC", 4, 6);
					rmAddAreaTerrainLayer(settlementArea2, "SandC", 2, 4);
					rmAddAreaTerrainLayer(settlementArea2, "SandB", 0, 2);
					rmBuildArea(settlementArea2);
					rmPlaceObjectDefAtAreaLoc(id, p, settlementArea2);
				}
			}
		}

		// Create Settlements
		else {
			for(p = 1; <= cNumberNonGaiaPlayers) {
				farID = rmCreateObjectDef("giant settlement" + p);
				rmAddObjectDefItem(farID, "Settlement", 1, 0.0);
				rmAddObjectDefConstraint(farID, TCavoidImpassableLand);
				rmAddObjectDefConstraint(farID, TCavoidStart);
				rmAddObjectDefConstraint(farID, TCavoidSettlement);
				for(attempt = 4; < 12) {
					rmPlaceObjectDefAtLoc(farID, p, rmGetPlayerX(p), rmGetPlayerZ(p), 1);
					if(rmGetNumberUnitsPlaced(farID) > 0) {
						break;
					}
					rmSetObjectDefMaxDistance(farID, 10 * attempt);
				}
				farID = rmCreateObjectDef("giant2 settlement" + p);
				rmAddObjectDefItem(farID, "Settlement", 1, 0.0);
				rmAddObjectDefConstraint(farID, TCavoidImpassableLand);
				rmAddObjectDefConstraint(farID, TCavoidStart);
				rmAddObjectDefConstraint(farID, TCavoidSettlement);
				for(attempt = 6; < 15) {
					rmPlaceObjectDefAtLoc(farID, p, rmGetPlayerX(p), rmGetPlayerZ(p), 1);
					if(rmGetNumberUnitsPlaced(farID) > 0){
						break;
					}
					rmSetObjectDefMaxDistance(farID, 10 * attempt);
				}
			}
		}
	}

	// Loading Status
	loadStatus(0.53);

	/* ************************** */
	/* Section 9 Starting Objects */
	/* ************************** */

	// Create Constraints
	int getOffTheTC = rmCreateTypeDistanceConstraint("Stop starting resources from somehow spawning on top of TC!", "AbstractSettlement", 16.0);
	int huntShortAvoidsStartingGoldMilky = rmCreateTypeDistanceConstraint("short hunty avoid gold", "gold", 10.0);

	// Create Gazelle
	int startingHuntableID = rmCreateObjectDef("starting hunt");
	rmAddObjectDefItem(startingHuntableID, "gazelle", rmRandInt(4,5), 3.0);
	rmSetObjectDefMaxDistance(startingHuntableID, 23.0);
	rmSetObjectDefMaxDistance(startingHuntableID, 26.0);
	rmAddObjectDefConstraint(startingHuntableID, huntShortAvoidsStartingGoldMilky);
	rmAddObjectDefConstraint(startingHuntableID, getOffTheTC);
	rmPlaceObjectDefPerPlayer(startingHuntableID, false);

	// Create Goats
	int closeCowsID = rmCreateObjectDef("close cows");
	rmAddObjectDefItem(closeCowsID, "goat", 2, 2.0);
	rmSetObjectDefMinDistance(closeCowsID, 25.0);
	rmSetObjectDefMaxDistance(closeCowsID, 30.0);
	rmAddObjectDefConstraint(closeCowsID, getOffTheTC);
	rmAddObjectDefConstraint(closeCowsID, avoidFood);
	rmPlaceObjectDefPerPlayer(closeCowsID, true);

	// Create Chickens
	int chickenShortAvoidsStartingGoldMilky = rmCreateTypeDistanceConstraint("short birdy avoid gold", "gold", 10.0);
	int startingChickenID = rmCreateObjectDef("starting birdies");
	rmAddObjectDefItem(startingChickenID, "Chicken", rmRandInt(6,10), 3.0);
	rmSetObjectDefMaxDistance(startingChickenID, 20.0);
	rmSetObjectDefMaxDistance(startingChickenID, 23.0);
	rmAddObjectDefConstraint(startingChickenID, avoidFood);
	rmAddObjectDefConstraint(startingChickenID, getOffTheTC);
	rmAddObjectDefConstraint(startingChickenID, chickenShortAvoidsStartingGoldMilky);

	// Create Bushes
	int startingBerryID = rmCreateObjectDef("starting berries");
	rmAddObjectDefItem(startingBerryID, "Berry Bush", rmRandInt(5,7), 2.0);
	rmSetObjectDefMaxDistance(startingBerryID, 21.0);
	rmSetObjectDefMaxDistance(startingBerryID, 25.0);
	rmAddObjectDefConstraint(startingBerryID, avoidFood);
	rmAddObjectDefConstraint(startingBerryID, chickenShortAvoidsStartingGoldMilky);
	rmAddObjectDefConstraint(startingBerryID, getOffTheTC);
	for(x = 1; <cNumberPlayers) {
		if(rmRandFloat(0.0, 1.0) < 0.5) {
			rmPlaceObjectDefAtLoc(startingChickenID, 0, rmGetPlayerX(x), rmGetPlayerZ(x));
		}
		else {
			rmPlaceObjectDefAtLoc(startingBerryID, 0, rmGetPlayerX(x), rmGetPlayerZ(x));
		}
	}

	// Create Palms
	int stragglerTreeID = rmCreateObjectDef("straggler tree");
	rmAddObjectDefItem(stragglerTreeID, "palm", 1, 0.0);
	rmSetObjectDefMinDistance(stragglerTreeID, 12.0);
	rmSetObjectDefMaxDistance(stragglerTreeID, 15.0);
	rmAddObjectDefConstraint(stragglerTreeID, rmCreateTypeDistanceConstraint("tree avoid all", "all", 3.0));
	rmPlaceObjectDefPerPlayer(stragglerTreeID, false, 3);

	// Loading Status
	loadStatus(0.60);

	/* *************************** */
	/* Section 10 Starting Forests */
	/* *************************** */

	// Create Constraints
	int forestTerrain = rmCreateTerrainDistanceConstraint("forest terrain", "Land", false, 3.0);
	int forestTC = rmCreateClassDistanceConstraint("starting forest vs starting settle", classStartingSettlement, 20.0);
	int forestOtherTCs = rmCreateTypeDistanceConstraint("starting forest vs settle", "AbstractSettlement", 20.0);

	// Create Forests
	int maxNum = 4;
	for(p=1; <= cNumberNonGaiaPlayers) {
		placePointsCircleCustom(rmXMetersToFraction(42.0), maxNum, -1.0, -1.0, rmGetPlayerX(p), rmGetPlayerZ(p), false, false);
		int skip = rmRandInt(1, maxNum);
		for(x = 1; <= maxNum) {
			if(x == skip) {
				continue;
			}
			int playerStartingForestID = rmCreateArea("player " + p + " forest " + x);
			rmSetAreaSize(playerStartingForestID, rmAreaTilesToFraction(75 + cNumberNonGaiaPlayers), rmAreaTilesToFraction(100 + cNumberNonGaiaPlayers));
			rmSetAreaLocation(playerStartingForestID, rmGetCustomLocXForPlayer(x), rmGetCustomLocZForPlayer(x));
			rmSetAreaWarnFailure(playerStartingForestID, true);
			rmSetAreaForestType(playerStartingForestID, "palm forest");
			rmAddAreaConstraint(playerStartingForestID, forestOtherTCs);
			rmAddAreaConstraint(playerStartingForestID, forestTC);
			rmAddAreaConstraint(playerStartingForestID, forestTerrain);
			rmAddAreaToClass(playerStartingForestID, classForest);
			rmSetAreaCoherence(playerStartingForestID, 0.25);
			rmBuildArea(playerStartingForestID);
		}
	}

	// Create Towers
	int avoidTower = rmCreateTypeDistanceConstraint("avoid tower", "tower", 20.0);
	int forestTower = rmCreateClassDistanceConstraint("tower v forest", classForest, 4.0);
	int startingTowerID = rmCreateObjectDef("Starting tower");
	rmAddObjectDefItem(startingTowerID, "tower", 1, 0.0);
	rmSetObjectDefMinDistance(startingTowerID, 21.0);
	rmSetObjectDefMaxDistance(startingTowerID, 24.0);
	rmAddObjectDefConstraint(startingTowerID, avoidTower);
	rmAddObjectDefConstraint(startingTowerID, rmCreateTypeDistanceConstraint("towerfood", "food", 8.0));
	rmAddObjectDefConstraint(startingTowerID, forestTower);
	rmAddObjectDefConstraint(startingTowerID, huntShortAvoidsStartingGoldMilky);
	int placement = 1;
	float increment = 1.0;
	for(p = 1; <= cNumberNonGaiaPlayers) {
		placement = 1;
		increment = 24;
		while(rmGetNumberUnitsPlaced(startingTowerID) < (4 * p)) {
			rmPlaceObjectDefAtLoc(startingTowerID, p, rmGetPlayerX(p), rmGetPlayerZ(p), 1);
			placement ++;
			if(placement % 2 == 0) {
				increment ++;
				rmSetObjectDefMaxDistance(startingTowerID, increment);
			}
		}
	}

	// Loading Status
	loadStatus(0.66);

	/* ************************* */
	/* Section 11 Medium Objects */
	/* ************************* */

	// Create Mines
	int mediumGoldID = rmCreateObjectDef("medium gold");
	rmAddObjectDefItem(mediumGoldID, "Gold mine", 1, 0.0);
	rmSetObjectDefMinDistance(mediumGoldID, 55.0);
	rmSetObjectDefMaxDistance(mediumGoldID, 60.0);
	rmAddObjectDefConstraint(mediumGoldID, goldAvoidsGold);
	rmAddObjectDefConstraint(mediumGoldID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(mediumGoldID, shortAvoidSettlement);
	rmAddObjectDefConstraint(mediumGoldID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(mediumGoldID, forestObjConstraint);
	rmPlaceObjectDefPerPlayer(mediumGoldID, false);

	// Create Gazelle
	int mediumGazelleID = rmCreateObjectDef("medium deer");
	rmAddObjectDefItem(mediumGazelleID, "gazelle", rmRandInt(6, 8), 3.0);
	rmSetObjectDefMinDistance(mediumGazelleID, 50.0);
	rmSetObjectDefMaxDistance(mediumGazelleID, 55.0);
	rmAddObjectDefConstraint(mediumGazelleID, avoidFood);
	rmAddObjectDefConstraint(mediumGazelleID, shortAvoidSettlement);
	rmAddObjectDefConstraint(mediumGazelleID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(mediumGazelleID, forestObjConstraint);
	rmPlaceObjectDefPerPlayer(mediumGazelleID, false);

	// Loading Status
	loadStatus(0.73);

	/* ********************** */
	/* Section 12 Far Objects */
	/* ********************** */

	// Create Gold
	int farGoldID = rmCreateObjectDef("far gold");
	rmAddObjectDefItem(farGoldID, "Gold mine", 1, 0.0);
	rmAddObjectDefConstraint(farGoldID, goldAvoidsGold);
	rmAddObjectDefConstraint(farGoldID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(farGoldID, shortAvoidSettlement);
	rmAddObjectDefConstraint(farGoldID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(farGoldID, forestObjConstraint);
	int goldNum = rmRandInt(2, 4);
	for(x = 1; < cNumberPlayers) {
		rmPlaceObjectDefInArea(farGoldID, x, rmAreaID("team" + rmGetPlayerTeam(x)), goldNum);
	}

	// Create Huntable 1
	int farAvoidFood = rmCreateTypeDistanceConstraint("avoid huntable", "food", 30.0);
	int bonusHuntableID = rmCreateObjectDef("bonus huntable");
	float bonusChance = rmRandFloat(0, 1);
	if(bonusChance < 0.3) {
		rmAddObjectDefItem(bonusHuntableID, "gazelle", 6, 2.0);
	}
	else if(bonusChance < 0.6) {
		rmAddObjectDefItem(bonusHuntableID, "zebra", 5, 2.0);
	}
	else {
		rmAddObjectDefItem(bonusHuntableID, "elephant", 5, 2.0);
	}
	rmAddObjectDefConstraint(bonusHuntableID, farAvoidFood);
	rmAddObjectDefConstraint(bonusHuntableID, avoidGold);
	rmAddObjectDefConstraint(bonusHuntableID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(bonusHuntableID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(bonusHuntableID, forestObjConstraint);
	rmPlaceObjectDefPerPlayer(bonusHuntableID, false, 1);
	for(x = 1; < cNumberPlayers) {
		rmPlaceObjectDefInArea(bonusHuntableID, 0, rmAreaID("team" + rmGetPlayerTeam(x)), 1);
	}

	// Create Huntable 2
	int bonusHuntableID2 = rmCreateObjectDef("bonus huntable 2");
	float bonusChance3 = rmRandFloat(0, 1);
	if(bonusChance3 < 0.3) {
		rmAddObjectDefItem(bonusHuntableID2, "gazelle", 5, 2.0);
	}
	else if(bonusChance3 < 0.6) {
		rmAddObjectDefItem(bonusHuntableID2, "zebra", 6, 2.0);
	}
	else {
		rmAddObjectDefItem(bonusHuntableID2, "elephant", 6, 2.0);
	}
	rmAddObjectDefConstraint(bonusHuntableID2, farAvoidFood);
	rmAddObjectDefConstraint(bonusHuntableID2, avoidGold);
	rmAddObjectDefConstraint(bonusHuntableID2, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(bonusHuntableID2, farStartingSettleConstraint);
	rmAddObjectDefConstraint(bonusHuntableID2, forestObjConstraint);
	for(x = 1; < cNumberPlayers) {
		rmPlaceObjectDefInArea(bonusHuntableID2, 0, rmAreaID("team" + rmGetPlayerTeam(x)), 1);
	}

	// Create Goats
	int farGoatsID = rmCreateObjectDef("far cows");
	rmAddObjectDefItem(farGoatsID, "goat", 2, 4.0);
	rmSetObjectDefMinDistance(farGoatsID, 80.0);
	rmSetObjectDefMaxDistance(farGoatsID, 100.0);
	rmAddObjectDefConstraint(farGoatsID, avoidFood);
	rmAddObjectDefConstraint(farGoatsID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(farGoatsID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(farGoatsID, forestObjConstraint);
	rmPlaceObjectDefPerPlayer(farGoatsID, false, 1);

	// Predator Constraint
	int avoidPredator=rmCreateTypeDistanceConstraint("avoid predator", "animalPredator", 20.0);

	// Create Scarabs
	int scarabNatureID = rmCreateObjectDef("scarab predator");
	rmAddObjectDefItem(scarabNatureID, "scarab", 1, 4.0);
	rmSetObjectDefMinDistance(scarabNatureID, 70.0);
	rmSetObjectDefMaxDistance(scarabNatureID, 90.0);
	rmAddObjectDefConstraint(scarabNatureID, avoidPredator);
	rmAddObjectDefConstraint(scarabNatureID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(scarabNatureID, forestObjConstraint);
	rmPlaceObjectDefPerPlayer(scarabNatureID, false, 2);
	for(x = 1; < cNumberPlayers) {
		rmPlaceObjectDefInArea(scarabNatureID, 0, rmAreaID("team" + rmGetPlayerTeam(x)), 1);
	}

	// Create Crocodiles
	int farPredatorID = rmCreateObjectDef("far predator");
	rmAddObjectDefItem(farPredatorID, "crocodile", 3, 4.0);
	rmSetObjectDefMinDistance(farPredatorID, 70.0);
	rmSetObjectDefMaxDistance(farPredatorID, 90.0);
	rmAddObjectDefConstraint(farPredatorID, avoidPredator);
	rmAddObjectDefConstraint(farPredatorID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(farPredatorID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(farPredatorID, forestObjConstraint);
	rmAddObjectDefConstraint(farPredatorID, avoidFood);
	rmAddObjectDefConstraint(farPredatorID, rmCreateTypeDistanceConstraint("preds avoid gold 132", "gold", 50.0));
	rmAddObjectDefConstraint(farPredatorID, rmCreateTypeDistanceConstraint("preds avoid settlements 132", "AbstractSettlement", 50.0));
	rmPlaceObjectDefPerPlayer(farPredatorID, false, 1);

	// Create Lions
	int farPredator2ID = rmCreateObjectDef("far predator 2");
	rmAddObjectDefItem(farPredator2ID, "lion", 2, 4.0);
	rmSetObjectDefMinDistance(farPredator2ID, 70.0);
	rmSetObjectDefMaxDistance(farPredator2ID, 100.0);
	rmAddObjectDefConstraint(farPredator2ID, avoidPredator);
	rmAddObjectDefConstraint(farPredator2ID, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(farPredator2ID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(farPredator2ID, forestObjConstraint);
	rmAddObjectDefConstraint(farPredator2ID, avoidFood);
	rmAddObjectDefConstraint(farPredator2ID, rmCreateTypeDistanceConstraint("preds avoid gold 141", "gold", 50.0));
	rmAddObjectDefConstraint(farPredator2ID, rmCreateTypeDistanceConstraint("preds avoid settlements 141", "AbstractSettlement", 50.0));
	rmPlaceObjectDefPerPlayer(farPredator2ID, false, 1);

	// Create Relics
	int relicID = rmCreateObjectDef("relic");
	rmAddObjectDefItem(relicID, "relic", 1, 0.0);
	rmAddObjectDefConstraint(relicID, rmCreateBoxConstraint("edge of map", rmXTilesToFraction(8), rmZTilesToFraction(8), 1.0 - rmXTilesToFraction(8), 1.0 - rmZTilesToFraction(8)));
	rmAddObjectDefConstraint(relicID, rmCreateTypeDistanceConstraint("relic vs relic", "relic", 40.0));
	rmAddObjectDefConstraint(relicID, farStartingSettleConstraint);
	rmAddObjectDefConstraint(relicID, forestObjConstraint);
	rmAddObjectDefConstraint(relicID, avoidGold);
	for(x = 1; <cNumberPlayers) {
		rmPlaceObjectDefInArea(relicID, 0, rmAreaID("team" + rmGetPlayerTeam(x)), 1);
	}

	// Create Palms
	int randomTreeID = rmCreateObjectDef("random tree");
	rmAddObjectDefItem(randomTreeID, "palm", 1, 0.0);
	rmSetObjectDefMinDistance(randomTreeID, 0.0);
	rmSetObjectDefMaxDistance(randomTreeID, rmXFractionToMeters(0.5));
	rmAddObjectDefConstraint(randomTreeID, rmCreateTypeDistanceConstraint("random tree", "all", 4.0));
	rmAddObjectDefConstraint(randomTreeID, shortAvoidSettlement);
	rmPlaceObjectDefAtLoc(randomTreeID, 0, 0.5, 0.5, 20 * cNumberNonGaiaPlayers);

	// Loading Status
	loadStatus(0.80);

	/* ************************ */
	/* Section 13 Giant Objects */
	/* ************************ */

	// Giant Maps
	if(cMapSize == 2) {

		// Create Gold
		int giantGoldID = rmCreateObjectDef("giant gold");
		rmAddObjectDefItem(giantGoldID, "Gold mine", 1, 0.0);
		rmSetObjectDefMaxDistance(giantGoldID, rmXFractionToMeters(0.25));
		rmSetObjectDefMaxDistance(giantGoldID, rmXFractionToMeters(0.35));
		rmAddObjectDefConstraint(giantGoldID, goldAvoidsGold);
		rmAddObjectDefConstraint(giantGoldID, rmCreateTypeDistanceConstraint("gold avoid settlements 141", "AbstractSettlement", 50.0));
		rmPlaceObjectDefPerPlayer(giantGoldID, false, 3);

		// Create Constraints
		int giantAvoidFood = rmCreateTypeDistanceConstraint("giant avoid food", "food", 50.0);

		// Create Elephants 1
		int giantHuntableID = rmCreateObjectDef("giant huntable");
		rmAddObjectDefItem(giantHuntableID, "elephant", 5, 4.0);
		rmSetObjectDefMaxDistance(giantHuntableID, rmXFractionToMeters(0.29));
		rmSetObjectDefMaxDistance(giantHuntableID, rmXFractionToMeters(0.36));
		rmAddObjectDefConstraint(giantHuntableID, avoidGold);
		rmAddObjectDefConstraint(giantHuntableID, giantAvoidFood);
		rmAddObjectDefConstraint(giantHuntableID, shortAvoidSettlement);
		rmAddObjectDefConstraint(giantHuntableID, farStartingSettleConstraint);
		rmPlaceObjectDefPerPlayer(giantHuntableID, false, 2);

		// Create Elephants 2
		int giantHuntable2ID = rmCreateObjectDef("giant huntable 2");
		rmAddObjectDefItem(giantHuntable2ID, "elephant", 5, 4.0);
		rmSetObjectDefMaxDistance(giantHuntable2ID, rmXFractionToMeters(0.29));
		rmSetObjectDefMaxDistance(giantHuntable2ID, rmXFractionToMeters(0.36));
		rmAddObjectDefConstraint(giantHuntable2ID, avoidGold);
		rmAddObjectDefConstraint(giantHuntable2ID, giantAvoidFood);
		rmAddObjectDefConstraint(giantHuntable2ID, shortAvoidSettlement);
		rmAddObjectDefConstraint(giantHuntable2ID, farStartingSettleConstraint);
		rmPlaceObjectDefPerPlayer(giantHuntable2ID, false, rmRandInt(1, 2));

		// Create Goats
		int giantHerdableID = rmCreateObjectDef("giant herdable");
		rmAddObjectDefItem(giantHerdableID, "goat", rmRandInt(2,4), 5.0);
		rmSetObjectDefMaxDistance(giantHerdableID, rmXFractionToMeters(0.25));
		rmSetObjectDefMaxDistance(giantHerdableID, rmXFractionToMeters(0.35));
		rmAddObjectDefConstraint(giantHerdableID, shortAvoidImpassableLand);
		rmAddObjectDefConstraint(giantHerdableID, farStartingSettleConstraint);
		rmAddObjectDefConstraint(giantHerdableID, forestObjConstraint);
		rmPlaceObjectDefPerPlayer(giantHerdableID, false, rmRandInt(1, 2));

		// Create Relics
		int giantRelicsID = rmCreateObjectDef("giant Relix");
		rmAddObjectDefItem(giantRelicsID, "relic", 1, 5.0);
		rmAddObjectDefConstraint(giantRelicsID, avoidGold);
		rmAddObjectDefConstraint(giantRelicsID, rmCreateTypeDistanceConstraint("relix avoid relix", "relic", 110.0));
		for(x = 1; < cNumberPlayers) {
			rmPlaceObjectDefInArea(giantRelicsID, x, rmAreaID("team" + rmGetPlayerTeam(x)), 1);
		}
	}

	// Loading Status
	loadStatus(0.86);

	/* ************************************ */
	/* Section 14 Map Fill Cliffs & Forests */
	/* ************************************ */

	// Create Contraints
	int forestConstraint=rmCreateClassDistanceConstraint("forest v forest", rmClassID("forest"), 20.0);
	int forestSettleConstraint=rmCreateClassDistanceConstraint("forest settle", rmClassID("starting settlement"), 20.0);
	int avoidImpassableLand=rmCreateTerrainDistanceConstraint("forests avoid impassable land", "land", false, 18.0);

	// Iterate Teams
	for(x = 0; < cNumberTeams) {
		failCount = 0;
		int forestCount = rmRandInt(4, 5) * rmGetNumberPlayersOnTeam(x);
		if(cMapSize == 2) {
			forestCount = 2.25 * forestCount;
		}

		// Iterate Forests
		for(y = 0; < forestCount) {

			// Create Area
			int forestID = rmCreateArea("team" + x + "forest" + y, rmAreaID("team" + x));
			rmSetAreaSize(forestID, rmAreaTilesToFraction(140), rmAreaTilesToFraction(200));
			if(cMapSize == 2) {
				rmSetAreaSize(forestID, rmAreaTilesToFraction(180), rmAreaTilesToFraction(240));
			}
			rmSetAreaWarnFailure(forestID, false);
			rmSetAreaForestType(forestID, "palm forest");
			rmAddAreaConstraint(forestID, forestSettleConstraint);
			rmAddAreaConstraint(forestID, shortAvoidSettlement);
			rmAddAreaConstraint(forestID, forestObjConstraint);
			rmAddAreaConstraint(forestID, forestConstraint);
			rmAddAreaConstraint(forestID, avoidImpassableLand);
			rmAddAreaToClass(forestID, classForest);
			rmSetAreaMinBlobs(forestID, 2);
			rmSetAreaMaxBlobs(forestID, 2);
			rmSetAreaMinBlobDistance(forestID, 5.0);
			rmSetAreaMaxBlobDistance(forestID, 5.0);
			rmSetAreaCoherence(forestID, 0.5);

			// Build Area
			if(rmBuildArea(forestID) == false) {
				failCount ++;
				if(failCount == 5 * mapSizeMultiplier) {
					break;
				}
			}
			else {
				failCount = 0;
			}
		}
	}

	// Loading Status
	loadStatus(0.93);

	/* ********************************* */
	/* Section 15 Beautification Objects */
	/* ********************************* */

	// Create Contraints
	int avoidAll = rmCreateTypeDistanceConstraint("avoid all", "all", 6.0);
	int connectionConstraint = rmCreateClassDistanceConstraint("stay away from connection", connectionClass, 4.0);

	// Create Rocks 1
	int rockID = rmCreateObjectDef("rock");
	rmAddObjectDefItem(rockID, "rock sandstone sprite", 1, 0.0);
	rmSetObjectDefMinDistance(rockID, 0.0);
	rmSetObjectDefMaxDistance(rockID, rmXFractionToMeters(0.5));
	rmAddObjectDefConstraint(rockID, avoidAll);
	rmPlaceObjectDefAtLoc(rockID, 0, 0.5, 0.5, 40 * cNumberNonGaiaPlayers);

	// Create Rocks 2
	int rockID2 = rmCreateObjectDef("rock 2");
	rmAddObjectDefItem(rockID2, "rock sandstone sprite", 3, 1.0);
	rmAddObjectDefItem(rockID2, "rock sandstone sprite", 3, 3.0);
	rmAddObjectDefItem(rockID2, "rock sandstone sprite", 2, 3.0);
	rmAddObjectDefItem(rockID2, "rock sandstone sprite", 1, 5.0);
	rmSetObjectDefMinDistance(rockID2, 0.0);
	rmAddObjectDefConstraint(rockID2, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(rockID2, avoidAll);
	rmAddObjectDefConstraint(rockID2, avoidBuildings);
	rmAddObjectDefConstraint(rockID2, connectionConstraint);
	rmSetObjectDefMaxDistance(rockID2, rmXFractionToMeters(0.5));
	for(x = 1; <cNumberNonGaiaPlayers * 6) {
		if(rmPlaceObjectDefAtLoc(rockID2, 0, 0.5, 0.5, 1) == 0) {
			break;
		}
	}

	// Create Rocks 3
	int rockID3 = rmCreateObjectDef("rock 3");
	rmAddObjectDefItem(rockID3, "rock sandstone sprite", 1, 2.0);
	rmAddObjectDefItem(rockID3, "rock sandstone sprite", 2, 5.0);
	rmAddObjectDefItem(rockID3, "rock sandstone sprite", 3, 5.0);
	rmSetObjectDefMinDistance(rockID3, 0.0);
	rmAddObjectDefConstraint(rockID3, shortAvoidImpassableLand);
	rmAddObjectDefConstraint(rockID3, avoidAll);
	rmAddObjectDefConstraint(rockID3, avoidBuildings);
	rmAddObjectDefConstraint(rockID3, connectionConstraint);
	rmSetObjectDefMaxDistance(rockID3, rmXFractionToMeters(0.5));
	for(x = 1; < cNumberNonGaiaPlayers * 3) {
		if(rmPlaceObjectDefAtLoc(rockID3, 0, 0.5, 0.5, 1) == 0) {
			break;
		}
	}

	// Create Hawks
	int farhawkID = rmCreateObjectDef("far hawks");
	rmAddObjectDefItem(farhawkID, "hawk", 1, 0.0);
	rmSetObjectDefMinDistance(farhawkID, 0.0);
	rmSetObjectDefMaxDistance(farhawkID, rmXFractionToMeters(0.5));
	rmPlaceObjectDefPerPlayer(farhawkID, false, 2);

	// Loading Complete
	loadStatus(1.0);
}