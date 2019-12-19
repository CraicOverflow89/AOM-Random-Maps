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
 * Limits a value to within a minimum and maximum value
 *
 * @param value The value to limit
 * @param min, max The limits of the value to enforce
 * @returns float
 */
float limitFloat(float value = 0.0, float min = 0.0, float max = 1.0) {
	if(value < min) return (min);
	if(value > max) return (max);
	return (value);
}

/**
 * Updates the loading status
 *
 * @param value Completion percentage
 * @returns void
 */
void loadStatus(float value = 0.0) {
	rmSetStatusText("", limitFloat(value));
}

/**
 * Performs a random check for success
 *
 * @param percent The percentage chance of success
 * returns bool
 */
bool randomSuccess(float percent = 0.5) {
	return (rmRandFloat(0, 1) > limitFloat(percent));
}