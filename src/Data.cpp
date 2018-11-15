#include "Data.h"

static size_t WriteCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

bool fileExists(const char* fileName) {
    std::ifstream infile(fileName);
    bool result = infile.good();
    infile.close();
    return result;
}

Data::Data(bool refresh) {
    if (refresh == true || !fileExists(DATACACHEDIRECTORY)) {
        printf("Pulling data from database. This may take a minute...\n");
        mkdir(DATACACHEDIRECTORY, 0777);
        for (int i = 1; i <= 23; i++) {
            CURL *curl = curl_easy_init();
            CURLcode res;
            std::string readBuffer = "";
            std::stringstream url;
            url << "https://sandbox-api.brewerydb.com/v2/beers?key=2762da2b0b0ce90d5562856acc3e30c9&format=xml&p=" << i;
            curl_easy_setopt(curl, CURLOPT_URL, url.str().c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
            res = curl_easy_perform(curl);
            if (res != CURLE_OK)
                fprintf(stderr, "Call to brewerydb failed: %d\n", res);
            curl_easy_cleanup(curl);
            curl_global_cleanup();

            // Put the data into a file
            std::ofstream file;
            std::stringstream fileName;
            fileName << DATACACHEDIRECTORY << "/" << i << ".xml";
            file.open(fileName.str());
            file << readBuffer;
            file.close();
        }
    }

    DIR *dir;
    std::vector<std::string> dirs;
    struct dirent * ent;
    dir = opendir(DATACACHEDIRECTORY);
    while ((ent = readdir(dir)) != NULL) {
        //printf("Found %s\n", ent->d_name);
        dirs.push_back(ent->d_name);
    }

    std::map<std::string, std::vector<std::string> > rawData;
    for (uint i = 0; i < dirs.size(); i++) {
        if (dirs[i].find(".xml") == std::string::npos)
            continue;
        pugi::xml_document doc;
        std::stringstream fileName;
        fileName << DATACACHEDIRECTORY << "/" << dirs[i].c_str();
        //printf("Getting beers from file: %s\n", dirs[i].c_str());
        pugi::xml_parse_result result = doc.load_file(fileName.str().c_str());
        if (!result) {
            printf("Failed to read xml\n");
            return;
        }

        pugi::xml_node data = doc.child("root").child("data");
        for (pugi::xml_node beerNode = data.first_child(); beerNode; beerNode = beerNode.next_sibling()) {
            std::vector<std::string> data;
            if (beerNode.child("name") != NULL)
                data.push_back(std::string(beerNode.child("name").child_value()));
            else
                data.push_back("No Name Found");
            if (beerNode.child("description") != NULL)
                data.push_back(beerNode.child("description").child_value());
            else {
                if (beerNode.child("style") != NULL && beerNode.child("style").child("description") != NULL)
                    data.push_back(beerNode.child("style").child("description").child_value());
                else
                    data.push_back("No Description Found");
            }
            if (beerNode.child("abv") != 0)
                data.push_back(beerNode.child("abv").child_value());
            else
                data.push_back("0");
            if (beerNode.child("ibu") != 0)
                data.push_back(beerNode.child("ibu").child_value());
            else
                data.push_back("0");
            if (beerNode.child("style") != 0 && beerNode.child("style").child("name") != 0)
                data.push_back(beerNode.child("style").child("name").child_value());
            else
                data.push_back("Unknown Style");
            rawData[beerNode.child("id").child_value()] = data;
        }
    }

    // char** tags and char** rawData
    std::map<std::string, std::vector<float> > convertedData = dataConversion(rawData);
}

Data::~Data() {

}