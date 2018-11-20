#include <fstream>
#include <map>
#include <stdio.h>
#include <string>
#include <vector>

__constant__ char* c_tags;

/*int getBit(unsigned char *bytes, int bit) {
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
}*/

__global__ void description_to_tags(char **d_descs, unsigned char *d_results, int sizeEntries, char **d_tags, int sizeTags) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    /*if (idx < sizeTags) {
        //c_tags[idx] = d_tags[idx];
        printf("Thread %d: %s\n", idx, d_tags[idx]);
    }*/
    if (idx >= sizeEntries)
        return;
    //char* desc = d_descs[idx];
    printf("Here with thread for idx: %d, %s\n", idx, d_descs[0]);
    //for (char *tag = *d_tags; tag; tag = *++d_tags) {
    for (int i = 0; i < sizeTags; i++) {
        /*char* tag = c_tags[i];
        //Check if the description contains the tag
        printf("%d: %s\n", idx, tag);
        while (*desc) {
            
        }*/
        printf("Thread %d: %s\n", idx, d_tags[i]);
    }
}

std::map<std::string, std::vector<float> > dataConversion(std::map<std::string, std::vector<std::string> > rawData, std::vector<std::string> tags_internal) {
    //const char** descData = new const char*[2000];
    const char** descData = (const char**) malloc(sizeof(char)*2000*rawData.size());
    int i = 0;
    // Put desc data into char**
    for (std::map<std::string, std::vector<std::string> >::iterator it = rawData.begin(); it != rawData.end(); it++) {
        /*printf("%s: ", it->first.c_str());
        for (uint i = 0; i < it->second.size(); i++) {
            printf("%s - ", it->second[i].c_str());
        }
        printf("\n");*/
        descData[i] = it->second[1].c_str();
        i++;
    }

    // Get Tag data
    const char* tags = (char*) malloc(sizeof(char) * 20 * tags_internal.size());
    memset(tags, '\0', 20*tags_internal.size());
    int i = 0;
    for (std::set<std::string>::iterator it = tags_internal.begin(); it != tags_internal.end(); ++it) {
        for (int j = 0; j < 20; j++) {
            tags[i*20+j] = (*it)[j];
        }
        i++;
    }

    std::map<std::string, std::vector<float> > results;
    
    /* Since we have 11Gb of memory on my GPU we don't need to worry about memory...at 
    85*20 bytes for the tags, 2000 bytes per beer for description, 11 bytes per beer for results
    it would take around 5.5 million beers to run out of memory...We don't have that*/
    const dim3 blockSize(1024, 1, 1);
    const dim3 gridSize(ceil(rawData.size()/1024.0), 1, 1);
    
    char **d_descs, **d_tags;
    unsigned char *d_results, *parsedResults;
    
    cudaMalloc(&d_results, 11*rawData.size());
    /*cudaMalloc(&d_tags, tags_internal.size()*20);
    cudaMemcpy(d_tags, &tags, tags_internal.size()*20, cudaMemcpyHostToDevice);
    //cudaMemcpyToSymbol(c_tags, &tags, tags_internal.size()*20, 0, cudaMemcpyHostToDevice);
    cudaMemcpyToSymbol("c_tags", d_tags, tags_internal.size()*20, 0, cudaMemcpyHostToDevice);
    cudaMemcpy(d_descs, descData, rawData.size()*2000, cudaMemcpyHostToDevice);
    cudaMemcpy(d_results, 0, 11*rawData.size(), cudaMemcpyHostToDevice);*/

    // Copy descs to device
    cudaMalloc(&d_descs, rawData.size()*sizeof(char*));
    char **d_temp_desc;
    d_temp_desc = (char **)malloc(rawData.size()*sizeof(char *));
    for (int i = 0; i < rawData.size(); i++){
        cudaMalloc(&(d_temp_desc[i]), 2000*sizeof(char));
        cudaMemcpy(d_temp_desc[i], descData[i], 2000*sizeof(char), cudaMemcpyHostToDevice);
        cudaMemcpy(d_descs+i, &(d_temp_desc[i]), sizeof(char *), cudaMemcpyHostToDevice);
    }
    free(d_temp_desc);
    
    // Copy tags to global memory
    cudaMalloc(&d_tags, tags_internal.size()*sizeof(char*));
    char **d_temp_tags;
    d_temp_tags = (char **)malloc(tags_internal.size()*sizeof(char*));
    for (int i = 0; i < tags_internal.size(); i++) {
        cudaMalloc(&(d_temp_tags[i]), 20*sizeof(char));
        cudaMemcpy(d_temp_tags[i], tags[i], 20*sizeof(char), cudaMemcpyHostToDevice);
        cudaMemcpy(d_tags+i, &(d_temp_tags[i]), sizeof(char *), cudaMemcpyHostToDevice);
    }
    free(d_temp_tags);
    
    // Copy tags to constant memory
    
    cudaMemcpyToSymbol(c_tags, tags, tags_internal.size()*20, 0, cudaMemcpyHostToDevice);

    description_to_tags<<<gridSize, blockSize>>>(d_descs, d_results, rawData.size(), d_tags, tags_internal.size());//, d_results, rawData.size(), d_tags);
    
    //parsedResults = (unsigned char*) malloc(11*rawData.size());
    //cudaMemcpy(parsedResults, d_results, 11*rawData.size(), cudaMemcpyDeviceToHost);
    //delete descData;
    ////cudaFree(c_tags);
    cudaFree(d_descs);
    cudaFree(d_results);
    free(parsedResults);
    free(descData);
    free(tags);
    return results;
}
