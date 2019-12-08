/**
 * Initialises the map size
 *
 * @param tiles Count of tiles for standard size
 * @returns Map size multiplier (1 or 2)
 */
int initMap(int tiles = 9000) {

	// Define Multiplier
	int mapSizeMultiplier = 1;

	// Large Map
	if(cMapSize == 1) {
		tiles = tiles * 1.3;
		rmEchoInfo("Large map");
	}

	// Giant Map
	else if(cMapSize == 2) {
		tiles = tiles * 2.6;
		rmEchoInfo("Giant map");
		mapSizeMultiplier = 2;
	}

	// Set Size
	int sizeL = 2.22 * sqrt(cNumberNonGaiaPlayers * tiles);
	int sizeW = 1.8 * sqrt(cNumberNonGaiaPlayers * tiles);
	rmEchoInfo("Map size=" + sizeL + "m x " + sizeW + "m");
	rmSetMapSize(sizeL, sizeW);

	// Return Multiplier
	return (mapSizeMultiplier);
}

/**
 * Updates the loading status
 *
 * @param value Completion percentage
 * @returns void
 */
void loadStatus(float value = 0.0) {
	rmSetStatusText("", value);
}