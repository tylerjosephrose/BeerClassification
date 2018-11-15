#include <map>
#include <stdio.h>
#include <string>
#include <vector>

__constant__ char** c_tags;

int getBit(unsigned char *bytes, int bit) {
    return ((bytes[(bit/8)] >> (bit % 8)) & 1);
}

__device__ void setBit(unsigned char *bytes, int bit, int val) {
    if (val == 1)
        bytes[(bit/8)] |= (1 << (bit % 8));
    else
        bytes [(bit/8)] &= ~(1 << (bit % 8));
}

void printBits(unsigned char *ptr, int sizeInBytes) {
    for (int i = 0; i < sizeInBytes * 8; i++) {
        printf("%d", getBit(ptr, i));
    }
    printf("\n");
}

__global__ void description_to_tags(char **d_descs, unsigned char *d_results) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    char* desc = d_descs[idx];
    

    //for (char *tag = *c_tags; tag; tag = *++c_tags) {
    for (int i = 0; i < 85; i++) {
        char* tag = c_tags[i];
        //Check if the description contains the tag
        printf("%d: %s\n", idx, tag);
        /*while (*desc) {
            
        }*/
    }
}

std::map<std::string, std::vector<float> > dataConversion(std::map<std::string, std::vector<std::string> > rawData) {
    const char** descData = new const char*[2000];
    int i = 0;
    for (std::map<std::string, std::vector<std::string> >::iterator it = rawData.begin(); it != rawData.end(); it++) {
        /*printf("%s: ", it->first.c_str());
        for (uint i = 0; i < it->second.size(); i++) {
            printf("%s - ", it->second[i].c_str());
        }
        printf("\n");*/
        descData[i] = it->second[1].c_str();
        i++;
    }

    for (int i = 0; i < rawData.size(); i++) {
        printf("%d: %s\n", i, descData[i]);
    }

    // Convert description from string to char**

    std::map<std::string, std::vector<float> > results;
    
    /* Since we have 11Gb of memory on my GPU we don't need to worry about memory...at 
    85*20 bytes for the tags, 2000 bytes per beer for description, 11 bytes per beer for results
    it would take around 5.5 million beers to run out of memory...We don't have that*/
    const dim3 blockSize(1024, 1, 1);
    const dim3 gridSize(ceil(rawData.size()/1024.0, 1, 1);
    
    char **d_descs;
    unsigned char *d_results, *parsedResults;
    
    cudaMalloc(&d_descs, rawData.size()*2000);
    cudaMalloc(&d_results, 11*rawData.size());
    cudaMemcpytoSymbol(c_tags, tags, tags.size()*20);
    cudaMemcpy(d_descs, descData, rawData.size()*2000, cudaMemcpyHostToDevice);
    cudaMemcpy(d_results, 0, 11*rawData.size(), cudaMemcpyHostToDevice);
    
    description_to_tags<<<gridSize, blockSize>>>(d_descs, d_results);
    
    parsedResults = malloc(11*rawData.size());
    cudaMemcpy(parsedResults, d_results, 11*rawData.size(), cudaMemcpyDeviceToHost);
    delete descData;
    cudaFree(d_tags);
    cudaFree(d_descs);
    cudaFree(d_results);
    
    return results;
}
