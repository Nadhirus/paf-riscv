#include <ctype.h>
#include <stdio.h>
#include "convert.h"
#include "parser.h"

char * labels[LABEL_MAX_NB] = {};
int labelAddr[LABEL_MAX_NB] = {};
int iLabel;

char * mnemonics[NB_OPS] = {"add", "addi", "and", "andi", "auipc", "beq", "bge", "bgeu", "blt", "bltu", "bne", "jal", "jalr", "lb", "lbu", "lh", "lhu", "lui", "lw", "or", "ori", "sb", "sh", "sll", "slli", "slt", "sltu", "sra", "srai", "srl", "srli", "sub", "sw", "xor", "xori"};
int32_t opcodes[NB_OPS] = {ADD, ADDI, AND, ANDI, AUIPC, BEQ, BGE, BGEU, BLT, BLTU, BNE, JAL, JALR, LB, LBU, LH, LHU, LUI, LW, OR, ORI, SB, SH, SLL, SLLI, SLT, SLTU, SRA, SRAI, SRL, SRLI, SUB, SW, XOR, XORI};

int args_expected(int32_t op)   {
    int32_t opcode = op & 0x7f;
    if(opcode == LUI || opcode == AUIPC || opcode == JAL)
        return 2;
    else
        return 3;
}

int is_valid(char c)     {
        return c != ' ' && c != '\t';
}

int pretreat(char* line)        {
    char* firstCom = strchr(line, '/');
    if (firstCom != NULL)   {
        *firstCom = '\0';
    }
        
    char* cur = line;
    char c = *cur;
        int i = 0;
    int instrReading = 0;
    int instrRead = 0;

        while (c != '\n' && c != '\0')   {
        if(isalpha(c))  {
            instrReading = 1;
        }
        if(c == ':')    {
            instrReading = 0;
        }
                if(is_valid(c))       {
                        line[i] = c;
                        i++;
                } else if(instrReading && !instrRead)   {
            line[i] = ',';
            i++;
            instrRead = 1;
        }
        c = *(++cur);
        }
    line[i] = '\0';

    cur = line;
    while(*cur != '\0') {
        *cur = tolower(*cur);
        cur++;
    }

    return i;
}

int32_t find_op(char* op)   {
    for(int i = 0; i < NB_OPS; i++) {
        if (strcmp(op, mnemonics[i]) == 0)  {
            return opcodes[i];
        }
    }
    return 0xffffffff;
}

int32_t read_register(char * pch, uint8_t regType, int32_t op)  {
    if(strlen(pch) < 2) {
        return 0xffffffff;
    } else  {
        if(pch[0] != 'x')   {
            return 0xffffffff;
        }
        char * cur = pch + 1;
        int index = 0;
        while (isdigit(*cur))   { 
            index = index * 10 + (*cur) - '0';
            cur++;
        }
        if (*cur != '\0')   {
            return 0xffffffff;
        }

        return register_convert(index, regType, op);
    }
}

int32_t read_immediate(char * pch, int32_t op)  {
    if(strlen(pch) < 1) {
        return 0xffffffff;
    } else  {
        int neg = 0;
        char * cur = pch;
        if(*cur == '-') {
            neg = 1;
            if (strlen(pch) < 2)    {
                return 0xffffffff;
            }
            cur++;
        }

        int value = 0;
        while (isdigit(*cur))   {
            value = value * 10 + (*cur) - '0';
            cur++;
        }
        if (*cur != '\0')   {
            return 0xffffffff;
        }

        return immediate_convert(value, op, neg);
    }
}

int32_t read_shamt(char * pch, int32_t op)  {
    if(strlen(pch) < 1) {
        return 0xffffffff;
    } else  {
        char * cur = pch;
        int value = 0;
        while (isdigit(*cur))   {
            value = value * 10 + (*cur) - '0';
            cur++;
        }
        if (*cur != '\0')   {
            return 0xffffffff;
        }

        return shamt_convert(value, op);
    }
}

int labelSearch(char* label)    {
    for(int i = 0; i < iLabel; i++) {
        if (strcmp(label, labels[i]) == 0)  {
            return i;
        }
    }

    return -1;
}

void parseLabels(char * line, int cursedAddr)   {
    if(strlen(line) < 1)    { return; }
    char * hasLabel = strchr(line, ':');
    if(hasLabel != NULL)    {
        char * label = strtok(line, ":");
        char * l = malloc(LABEL_MAX_NB * sizeof(char));
        if(labelSearch(label) != -1)    {
            fprintf(stderr, "The label %s is already used.\n", label);
        }
        strcpy(l, label);
        labels[iLabel] = l;
        labelAddr[iLabel] = cursedAddr;
        iLabel++;
    }
}

int32_t parse(char* line, int cursedAddr)   {
    char * hasLabel = strchr(line, ':');
    if (hasLabel != NULL)  {
        strtok(line, ":");
    }
    if(strlen(line) < 1)    { return 0xfffffffe; }
    char * pch;
    if(hasLabel != NULL)
        pch = strtok(NULL, ",");
    else
        pch = strtok(line, ",");
    int32_t op = find_op(pch);
    if (op == 0xffffffff)   {
        fprintf(stderr, "Unknown instruction : %s\n", pch);
        return 0xffffffff;
    }

    int32_t opcode = op & 0x7f;
    int32_t instr = op;
    
    //We first try to find rd if required
    if (opcode != BRANCH && opcode != STORE)    {

        pch = strtok(NULL, ",");
        if (pch == NULL)    {
            fprintf(stderr, "Not enough arguments : 0 given, %d expected.\n", args_expected(op));
            return 0xffffffff;
        }
        
        int32_t rd = read_register(pch, DST_REG, op);
        if (rd == 0xffffffff)   {
            fprintf(stderr, "Invalid register expression : %s\n", pch);
            return 0xffffffff;
        }

        if (opcode == LUI || opcode == AUIPC || opcode == JAL)  {
            
            pch = strtok(NULL, ",");
            if (pch == NULL)    {
                fprintf(stderr, "Not enough arguments : 1 given, %d expected.\n", args_expected(op));
                return 0xffffffff;
            }

            int32_t imm;
            if(opcode != JAL)   {
                imm = read_immediate(pch, op);
                if (imm == 0xffffffff)  {
                    fprintf(stderr, "Invalid immediate value : %s\n", pch);
                    return 0xffffffff;
                }
            } else  {
                int i = labelSearch(pch);
                if (i == -1)    {
                    fprintf(stderr, "Label %s doesn't exist.\n", pch);
                    return 0xffffffff;
                }
                imm = immediate_convert(labelAddr[i] - cursedAddr, op, 0);
            }

            return instr | rd | imm;
        } else  {

            pch = strtok(NULL, ",");
            if(pch == NULL) {
                fprintf(stderr, "Not enough arguments : 1 given, %d expected.\n", args_expected(op));
                return 0xffffffff;
            }

            int32_t rs1 = read_register(pch, SRC1_REG, op);
            if (rs1 == 0xffffffff)  {
                fprintf(stderr, "Invalid register value : %s\n", pch);
                return 0xffffffff;
            }

            if (opcode == REG_OP)   {

                pch = strtok(NULL, ",");
                if(pch == NULL) {
                    fprintf(stderr, "Not enough arguments : 2 given, %d expected.\n", args_expected(op));
                    return 0xffffffff;
                }

                int32_t rs2 = read_register(pch, SRC2_REG, op);
                if(rs2 == 0xffffffff)   {
                    fprintf(stderr, "Invalid register value : %s\n", pch);
                    return 0xffffffff;
                }

                if (strtok(NULL, ",") != NULL)
                    fprintf(stderr, "Too many arguments.\n");
                else
                    return op | rd | rs1 | rs2;
            } else if (op == SLLI || op == SRLI || op == SRAI)  {

                pch = strtok(NULL, ",");
                if(pch == NULL) {
                    fprintf(stderr, "Not enough arguments : 2 given, %d expected.\n", args_expected(op));
                    return 0xffffffff;
                }

                int32_t shamt = read_shamt(pch, op);
                if(shamt == 0xffffffff) {
                    fprintf(stderr, "Invalid shamt value : %s\n", pch);
                    return 0xffffffff;
                }

                if (strtok(NULL, ",") != NULL)
                    fprintf(stderr, "Too many arguments.\n");
                else
                    return op | rd | rs1 | shamt;
            } else  {

                pch = strtok(NULL, ",");
                if(pch == NULL) {
                    fprintf(stderr, "Not enough arguments : 2 given, %d expected.\n", args_expected(op));
                    return 0xffffffff;
                }

                int32_t imm = read_immediate(pch, op);
                if (imm == 0xffffffff)  {
                    fprintf(stderr, "Invalid immediate value : %s\n", pch);
                    return 0xffffffff;
                }
                
                if (strtok(NULL, ",") != NULL)
                    fprintf(stderr, "Too many arguments.\n");
                else
                    return op | rd | rs1 | imm;
            }
        }
    } else  {
        
        pch = strtok(NULL, ",");
        if(pch == NULL) {
            fprintf(stderr, "Not enough arguments : 0 given, %d expected.\n", args_expected(op));
            return 0xffffffff;
        }

        int32_t rs1 = read_register(pch, SRC1_REG, op);
        if(rs1 == 0xffffffff)   {
            fprintf(stderr, "Invalid register value : %s\n", pch);
            return 0xffffffff;
        }

        pch = strtok(NULL, ",");
        if(pch == NULL) {
            fprintf(stderr, "Not enough arguments : 1 given, %d expected.\n", args_expected(op));
            return 0xffffffff;
        }

        int32_t rs2 = read_register(pch, SRC2_REG, op);
        if(rs2 == 0xffffffff)   {
            fprintf(stderr, "Invalid register value : %s\n", pch);
            return 0xffffffff;
        }

        pch = strtok(NULL, ",");
        if(pch == NULL) {
            fprintf(stderr, "Not enough arguments : 2 given, %d expected.\n", args_expected(op));
            return 0xffffffff;
        }

        if(opcode != BRANCH)    {
            int32_t imm = read_immediate(pch, op);
            if(imm == 0xffffffff)   {
                fprintf(stderr, "Invalid immset value : %s\n", pch);
                return 0xffffffff;
            }

            if(strtok(NULL, ",") != NULL)
                fprintf(stderr, "Too many arguments.\n");
            else
                return op | rs1 | rs2 | imm;
        } else  {
            int i = labelSearch(pch);
            if (i == -1)    {
                fprintf(stderr, "Label %s doesn't exist.\n", pch);
                return 0xffffffff;
            }
            int32_t imm = immediate_convert(labelAddr[i] - cursedAddr, op, 0);
            return op | rs1| rs2 | imm;
        }
    }
}
