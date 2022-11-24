/* This header defines the functions used by the parser */

#ifndef PARSER_HEADER
#define PARSER_HEADER

#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include "opcodes.h"

#define LABEL_MAX_LENGTH 50
#define LABEL_MAX_NB 100

char * labels[LABEL_MAX_NB];
int labelAddr[LABEL_MAX_NB];
int iLabel;

char * mnemonics[NB_OPS];
int32_t opcodes[NB_OPS];

int is_valid(char c);
int pretreat(char* line);
int32_t find_op(char* op);
int32_t parse(char* line, int addr);
int args_expected(int32_t op);
void parseLabels(char * line, int32_t cursed_addr);

#endif
