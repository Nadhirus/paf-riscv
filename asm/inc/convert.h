/* This header declares several functions that converts the index
   of registers or immediate values to bit sequences usable in
   the final instruction */

#ifndef CONVERT_HEADER
#define CONVERT_HEADER

#include <stdint.h>

#include "opcodes.h"

#define SRC1_REG	15
#define SRC2_REG	20
#define DST_REG		7

int32_t register_convert(uint8_t index, int8_t regtype, int32_t opcode);

int32_t immediate_convert(int32_t value, int32_t opcode, int neg);
int32_t shamt_convert(uint8_t value, int32_t opcode);

#endif
