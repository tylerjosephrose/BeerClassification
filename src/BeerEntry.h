#ifndef BEERENTRY_H
#define BEERENTRY_H

#include <string>
#include <vector>

struct BeerEntry {
    std::string style;
    std::vector<float> values;
};

#endif