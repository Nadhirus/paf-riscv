#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "parser.h"

int main(int argc, char* argv[])	{

	if(argc < 2)	{
		fprintf(stderr, "No input file provided.\n");
		return -1;
	}

	int addr = 0;
	FILE * input = fopen(argv[1], "r");
	FILE * output = fopen("out.bin", "w");
	int i = 0;

	char line[300] = "";

    while (fgets(line, 100, input) != NULL)	{
		i++;
		pretreat(line);
		parseLabels(line, addr);
        if(strlen(line) > 0)
			addr += 4;
	}

    rewind(input);
    addr = 0;
    i = 0;
	while (fgets(line, 100, input) != NULL)	{
		i++;
		pretreat(line);
		int p = parse(line, addr);
		if(p < 0xfffffffe)	{
			fprintf(output, "%08x\n", p);
			addr += 4;
		} else if(p == 0xffffffff)	{
			fprintf(stderr, "Errors on line %d\n", i);
		}
	}

	fclose(output);
	fclose(input);

	return 0;
}
