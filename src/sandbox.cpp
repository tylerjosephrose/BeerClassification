#include <iostream>

#include "Data.h"

int main(int argc, char *argv[]) {
	Data* data = new Data();
	data->print();
	delete data;
}