#include <curl/curl.h>
#include <dirent.h>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <vector>

#include "../pugixml/src/pugixml.hpp"

/*
Data is all the beer data we have stored which contains a map of beers with their data. The key 
for the data is the id found for the beer in brewerydb. The data contained is an array of 
strings starting with the name of the beer, a 1 or 0 for each tag the beer contains, the ABV of 
the beer, the IBU of the beer, and the style of the beer.
*/

// Functions from DataParse.cu
void descriptionToTags(std::map<std::string, std::vector<std::string> > rawData);

class Data {
public:
    Data(bool refresh = false);
    ~Data();

private:
    const char* DATACACHEDIRECTORY = "data_cache";
    std::map<std::string, std::string> beerData;
};