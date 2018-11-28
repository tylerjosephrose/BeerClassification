#include <iostream>
#include <ctime>
#include <time.h>

#include "Data.h"

int main() {
	std::time_t startTime = std::time(0);
	Data* data = new Data();
	std::time_t postParseTime = std::time(0);
	//data->print();
	data->train();
	std::time_t finalTime = std::time(0);
	double parseTimeSeconds = difftime(postParseTime, startTime);
	double networkTimeSeconds = difftime(finalTime, postParseTime);
	double totalTimeSeconds = parseTimeSeconds + networkTimeSeconds;
	printf("Timing Data Parallel:\n\tParsing - %f seconds\n\tTraining - %f seconds\n\tTotal - %f seconds\n", parseTimeSeconds, networkTimeSeconds, totalTimeSeconds);
	delete data;
}