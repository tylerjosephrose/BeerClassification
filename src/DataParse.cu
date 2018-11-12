#include <map>
#include <stdio.h>
#include <string>
#include <vector>

void descriptionToTags(std::map<std::string, std::vector<std::string> > rawData) {
    // make kernel call
    printf("in cuda code size: %d\n", rawData.size());
    for (std::map<std::string, std::vector<std::string> >::iterator it = rawData.begin(); it != rawData.end(); it++) {
        printf("%s: ", it->first.c_str());
        for (uint i = 0; i < it->second.size(); i++) {
            //printf("%s ", it->second[i].c_str());
        }
        printf("\n");
    }
}