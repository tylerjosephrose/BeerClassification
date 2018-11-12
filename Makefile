NVCC=nvcc

###################################
# These are the default install   #
# locations on most linux distros #
###################################

#OPENCV_LIBPATH=/usr/local/lib64
#OPENCV_INCLUDEPATH=/usr/local/include/opencv4

###################################################
# On Macs the default install locations are below #
###################################################

#OPENCV_LIBPATH=/usr/local/lib
#OPENCV_INCLUDEPATH=/usr/local/include

#OPENCV_LIBS=-lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_imgcodecs
CUDA_INCLUDEPATH=/usr/local/cuda-10.0/include

######################################################
# On Macs the default install locations are below    #
# ####################################################

#CUDA_INCLUDEPATH=/usr/local/cuda/include
#CUDA_LIBPATH=/usr/local/cuda/lib

NVCC_OPTS=-O3 -arch=sm_61 -Xcompiler -Wall -Xcompiler -Wextra -m64 -lcurl
GCC_OPTS=-O3 -Wall -Wextra -m64 -std=c++11 -lcurl


#student: main.o student_func.o HW3.o loadSaveImage.o compare.o reference_calc.o Makefile
#	$(NVCC) -o HW3 main.o student_func.o HW3.o loadSaveImage.o compare.o reference_calc.o -L $(OPENCV_LIBPATH) $(OPENCV_LIBS) $(NVCC_OPTS)
#
#main.o: main.cpp timer.h utils.h reference_calc.h compare.h
#	g++ -c main.cpp $(GCC_OPTS) -I $(CUDA_INCLUDEPATH)
#
#HW3.o: HW3.cu loadSaveImage.h utils.h
#	$(NVCC) -c HW3.cu -I $(OPENCV_INCLUDEPATH) $(NVCC_OPTS)
#
#loadSaveImage.o: loadSaveImage.cpp loadSaveImage.h
#	g++ -c loadSaveImage.cpp -I $(OPENCV_INCLUDEPATH) $(GCC_OPTS) -I $(CUDA_INCLUDEPATH)
#
#compare.o: compare.cpp compare.h
#	g++ -c compare.cpp -I $(OPENCV_INCLUDEPATH) $(GCC_OPTS) -I $(CUDA_INCLUDEPATH)
#
#reference_calc.o: reference_calc.cpp reference_calc.h
#	g++ -c reference_calc.cpp -I $(OPENCV_INCLUDEPATH) $(GCC_OPTS) -I $(CUDA_INCLUDEPATH)
#
#student_func.o: student_func.cu utils.h
#	$(NVCC) -c student_func.cu $(NVCC_OPTS)


all: DataParse.o Data.o sandbox.o
	$(NVCC) -o sandbox DataParse.o Data.o sandbox.o $(NVCC_OPTS)

DataParse.o: src/DataParse.cu
	$(NVCC) -c src/DataParse.cu $(NVCC_OPTS)

Data.o: src/Data.h src/Data.cpp
	g++ -c src/Data.cpp $(GCC_OPTS)

sandbox.o: src/sandbox.cpp
	g++ -c src/sandbox.cpp $(GCC_OPTS)

pugixml.o: pugixml/src/pugiconfig.hpp pugixml/src/pugixml.hpp pugixml/src/pugixml.cpp
	g++ -c pugixml/src/pugixml.cpp $(GCC_OPTS)

run: all
	./sandbox

clean:
	rm -f *.o
	rm sandbox