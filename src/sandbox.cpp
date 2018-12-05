#include <iostream>
#include <chrono>
#include <ctime>
#include <time.h>

#include "Data.h"


// ...

/*using namespace std::chrono;
milliseconds ms = duration_cast< milliseconds >(
    system_clock::now().time_since_epoch()
);*/
int main() {
	//std::time_t startTime = std::time(0);
	std::chrono::time_point<std::chrono::system_clock> startTime = std::chrono::system_clock::now();
	Data* data = new Data();
	//std::time_t postParseTime = std::time(0);
	std::chrono::time_point<std::chrono::system_clock> postParseTime = std::chrono::system_clock::now();
	//data->print();
	data->train();
	//std::time_t finalTime = std::time(0);
	std::chrono::time_point<std::chrono::system_clock> finalTime = std::chrono::system_clock::now();
	std::chrono::milliseconds parseTime = std::chrono::duration_cast<std::chrono::milliseconds>(postParseTime - startTime);
	std::chrono::milliseconds networkTime = std::chrono::duration_cast<std::chrono::milliseconds>(finalTime - postParseTime);
	std::chrono::milliseconds totalTime = std::chrono::duration_cast<std::chrono::milliseconds>(finalTime - startTime);
	printf("Timing Data Parallel:\n\tParsing - %d milliseconds\n\tTraining - %d milliseconds\n\tTotal - %d milliseconds\n", parseTime.count(), networkTime.count(), totalTime.count());
	delete data;
}