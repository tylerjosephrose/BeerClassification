#ifndef DATA_H
#define DATA_H

#include <curl/curl.h>
#include <dirent.h>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <vector>

#include "../pugixml/src/pugixml.hpp"
#include "BeerEntry.h"

/*
Data is all the beer data we have stored which contains a map of beers with their data. The key 
for the data is the id found for the beer in brewerydb. The data contained is an array of 
strings starting with the name of the beer, a 1 or 0 for each tag the beer contains, the ABV of 
the beer, the IBU of the beer, and the style of the beer.
*/

// Functions from DataParse.cu
std::vector<BeerEntry> dataConversion(std::map<std::string, std::vector<std::string> > rawData, std::vector<std::string> tags_internal);

class Data {
public:
    Data(bool refresh = false);
    ~Data();

    void train();
    void print();

private:
    const char* DATACACHEDIRECTORY = "data_cache";
    std::map<std::string, std::string> beerData;
    std::vector<std::string> y;
    std::vector< std::vector<float> >x;
    int numEntries = 0;
};

#endif