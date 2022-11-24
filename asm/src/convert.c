#include "convert.h"

int32_t register_convert(uint8_t index, int8_t regType, int32_t completeOpcode)	{
	int32_t opcode = completeOpcode & 0x7f;
	if (index > 31 || !(regType == SRC1_REG || regType == SRC2_REG || DST_REG))	{
		return 0xffffffff;
	}
	if ((regType == DST_REG && (opcode == BRANCH || opcode == STORE)) || 
		(regType == SRC1_REG && (opcode == LUI || opcode == AUIPC || opcode == JAL)) || 
		(regType == SRC2_REG && (opcode == LUI || opcode == AUIPC || opcode == JAL || opcode == JALR || opcode == LOAD || opcode == IMM_OP)))	{
		return 0;
	}
	return index << regType;
}

int32_t immediate_convert(int32_t value, int32_t completeOpcode, int neg)	{
	int32_t opcode = completeOpcode & 0x7f;
	if (neg)	{
		value = ~value;
		value += 1;
	}
	if (opcode == BRANCH)	{
		if (value & 1 || value > 0x1fff)
			return 0xffffffff;
		return 	((value & (1 		<< 12)) << 19) |
			((value & (0x3f 	<< 5)) << 20) |
			((value & (0xf 		<< 1)) << 7) |
			((value & (1		<< 11)) >> 4);
	} else if (opcode == LOAD || opcode == IMM_OP || opcode == JALR)	{
		if (value > 0xfff)
			return 0xffffffff;
		return 	((value & (0xfff	<< 0)) << 20);
	} else if (opcode == STORE)	{
		if (value > 0xfff)
			return 0xffffffff;
		return 	((value & (0x7f		<< 5)) << 20) |
			((value & (0x1f		<< 0 )) << 7);
	} else if (opcode == LUI || opcode == AUIPC)	{
		if (value & 0xfff)
			return 0xffffffff;
		return	((value & (0xfffff 	<< 12)) >> 0);
	} else if (opcode == JAL)	{
		if (value & 1 || value > 0x1fffff)
			return 0xffffffff;
		return 	((value & (1 		<< 20)) << 11) |
			((value & (0x3ff 	<< 1)) << 20) |
			((value & (0xff 	<< 12)) << 0) |
			((value & (1		<< 11)) << 9);
	} else	{
		return 0;
	}
}

int32_t shamt_convert(uint8_t value, int32_t completeOpcode)	{
	if (!(completeOpcode == SLLI || completeOpcode == SRLI || completeOpcode == SRAI))	{
		return 0;
	}
	if (value > 31)	{
		return 0xffffffff;
	}
	return value << 20;
}
