#include <fstream>
#include <map>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>

#define CUDA_ERROR_CHECK

#define CudaSafeCall( err ) __cudaSafeCall( err, __FILE__, __LINE__ )

inline void __cudaSafeCall( cudaError err, const char *file, const int line )
{
#ifdef CUDA_ERROR_CHECK
    if ( cudaSuccess != err )
    {
        fprintf( stderr, "cudaSafeCall() failed at %s:%i : %s\n",
                 file, line, cudaGetErrorString( err ) );
        exit( -1 );
    }
#endif

    return;
}

int getBit(unsigned char *bytes, int bit) {
    return ((bytes[(bit/8)] >> (bit % 8)) & 1);
}

/*__device__ void setBit(unsigned char *bytes, int bit, int val) {
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
    if (threadIdx.x > 0) 
        return;
    for (int num = 0; num < sizeTags; num++) {
        for (int i = 0; i < sizeEntries; i++) {
            int spacing = sizeEntries/sizeTags;
            int idx = (i + threadIdx.x*spacing) % sizeEntries;

            // Copy the desc locally so we don't have read conflicts
            int j = 0;
            char desc[2000];
            while (d_descs[idx][j] != '\0') {
                desc[j] = d_descs[idx][j];
                j++;
            }
            desc[j] = '\0';

            //char* tag = d_tags[threadIdx.x];
            char* tag = d_tags[num];
            int tagLength = 0;
            while (tag[tagLength] != '\0')
                tagLength++;
            
            int match = 0;
            bool positiveMatch = false;
            j = 0;
            while (desc[j] != '\0') {
                char descLetter = desc[j];
                if ('A'<=descLetter && descLetter<='Z'){
                    descLetter=char(((int)descLetter)+32);
                }

                if (descLetter == tag[match]) {
                    match++;
                    if (match == tagLength) {
                        positiveMatch = true;
                        break;
                    }
                }
                else
                    match = 0;
                j++;
            }
            
            if (positiveMatch) {
                //printf("Thread %d:%d is looking for %s\t%s\n", threadIdx.x, idx, tag, "True!");
                // Since 11 bytes are given for each entry we need to find the byte that we are in and add the specific flag we need
                switch (num % 8) {
                    case 0:
                        d_results[(num/8) * i] |= 0b10000000;
                        break;
                    case 1:
                        d_results[(num/8) * i] |= 0b01000000;
                        break;
                    case 2:
                        d_results[(num/8) * i] |= 0b00100000;
                        break;
                    case 3:
                        d_results[(num/8) * i] |= 0b00010000;
                        break;
                    case 4:
                        d_results[(num/8) * i] |= 0b00001000;
                        break;
                    case 5:
                        d_results[(num/8) * i] |= 0b00000100;
                        break;
                    case 6:
                        d_results[(num/8) * i] |= 0b00000010;
                        break;
                    case 7:
                        d_results[(num/8) * i] |= 0b00000001;
                        break;
                }
            }
            else {
                //printf("Thread %d:%d is looking for %s\t%s\n", threadIdx.x, idx, tag, "False");
                switch (num % 8) {
                    case 0:
                        d_results[(num/8) * i] &= ~0b10000000;
                        break;
                    case 1:
                        d_results[(num/8) * i] &= ~0b01000000;
                        break;
                    case 2:
                        d_results[(num/8) * i] &= ~0b00100000;
                        break;
                    case 3:
                        d_results[(num/8) * i] &= ~0b00010000;
                        break;
                    case 4:
                        d_results[(num/8) * i] &= ~0b00001000;
                        break;
                    case 5:
                        d_results[(num/8) * i] &= ~0b00000100;
                        break;
                    case 6:
                        d_results[(num/8) * i] &= ~0b00000010;
                        break;
                    case 7:
                        d_results[(num/8) * i] &= ~0b00000001;
                        break;
                }
            }
            __syncthreads();
        }
    }
}

std::map<std::string, std::vector<float> > dataConversion(std::map<std::string, std::vector<std::string> > rawData, std::vector<std::string> tags_internal) {
    const char** descData = (const char**) malloc(sizeof(char)*2000*rawData.size());
    // Collected data is other data that we need to return we collect it so we don't need to iterate through the map again and worry about order.
    // The data is the style of the beer, abv, ibu
    std::vector< std::vector<std::string> > collectedData;
    int i = 0;
    // Put desc data into char**
    for (std::map<std::string, std::vector<std::string> >::iterator it = rawData.begin(); it != rawData.end(); it++) {
        descData[i] = it->second[1].c_str();
        std::vector<std::string> data;
        data.push_back(it->second[4].c_str());
        data.push_back(it->second[2].c_str());
        data.push_back(it->second[3].c_str());
        collectedData.push_back(data);
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
    const dim3 blockSize(tags_internal.size(), 1, 1);
    const dim3 gridSize(1, 1, 1);
    
    char **d_descs, **d_tags;
    unsigned char *d_results;
    
    unsigned char *parsedResults = (unsigned char*) malloc(11*rawData.size());
    CudaSafeCall(cudaMalloc(&d_results, 11*rawData.size()));

    // Copy descs to device
    CudaSafeCall(cudaMalloc(&d_descs, rawData.size()*sizeof(char*)));
    char **d_temp_desc;
    d_temp_desc = (char **)malloc(rawData.size()*sizeof(char *));
    for (int i = 0; i < rawData.size(); i++){
        CudaSafeCall(cudaMalloc(&(d_temp_desc[i]), 2000*sizeof(char)));
        CudaSafeCall(cudaMemcpy(d_temp_desc[i], descData[i], 2000*sizeof(char), cudaMemcpyHostToDevice));
        CudaSafeCall(cudaMemcpy(d_descs+i, &(d_temp_desc[i]), sizeof(char *), cudaMemcpyHostToDevice));
    }
    free(d_temp_desc);

    // Copy tags to global memory
    CudaSafeCall(cudaMalloc(&d_tags, tags_internal.size()*sizeof(char*)));

    char **d_temp_tags;
    d_temp_tags = (char **)malloc(tags_internal.size()*sizeof(char*));
    for (int i = 0; i < tags_internal.size(); i++) {
        CudaSafeCall(cudaMalloc(&(d_temp_tags[i]), 20*sizeof(char)));
        CudaSafeCall(cudaMemcpy(d_temp_tags[i], tags[i], 20*sizeof(char), cudaMemcpyHostToDevice));
        CudaSafeCall(cudaMemcpy(d_tags+i, &(d_temp_tags[i]), sizeof(char *), cudaMemcpyHostToDevice));
    }
    free(d_temp_tags);
    
    // Copy tags to constant memory
    
    cudaMemcpyToSymbol(c_tags, tags, tags_internal.size()*20, 0, cudaMemcpyHostToDevice);

    description_to_tags<<<gridSize, blockSize>>>(d_descs, d_results, rawData.size(), d_tags, tags_internal.size());

    CudaSafeCall(cudaMemcpy(parsedResults, d_results, 11*rawData.size(), cudaMemcpyDeviceToHost));

    for (int i = 0; i < rawData.size(); i++) {
        std::vector<float> entry;
        // Put tag results into vector
        for (int j = 0; j < 88; j++) {
            entry.push_back((float) getBit(parsedResults, i*88 + j));
            //printf("entry[-1]);
        }
        // Add abv and ibu
        entry.push_back(atof(collectedData[i][1].c_str()));
        entry.push_back(atof(collectedData[i][2].c_str()));
        results[collectedData[i][0]] = entry;
    }
    
    CudaSafeCall(cudaFree(d_descs));
    CudaSafeCall(cudaFree(d_results));
    free(parsedResults);
    free(descData);
    free(tags);
    return results;
}
