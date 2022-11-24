/* This header defines the complete "opcodes" in RISCV.
 * By "complete opcodes" we mean a characteristic sequence of bits.
 *
 * Some instructions are characterized only by the opcode,
 * others by the opcode + funct3 (+ funct7).
 */

//Some general opcodes
#define BRANCH	0b1100011
#define LOAD	0b0000011
#define STORE	0b0100011
#define IMM_OP	0b0010011
#define REG_OP	0b0110011

#define NB_OPS 	37

#define LUI     (0b0110111)
#define AUIPC   (0b0010111)

#define JAL     (0b1101111)
#define JALR    (0b1100111 | (0b000 << 12))

#define BEQ     (0b1100011 | (0b000 << 12))
#define BNE     (0b1100011 | (0b001 << 12))
#define BLT     (0b1100011 | (0b100 << 12))
#define BGE     (0b1100011 | (0b101 << 12))
#define BLTU    (0b1100011 | (0b110 << 12))
#define BGEU    (0b1100011 | (0b111 << 12))

#define LB      (0b0000011 | (0b000 << 12))
#define LH      (0b0000011 | (0b001 << 12))
#define LW      (0b0000011 | (0b010 << 12))
#define LBU     (0b0000011 | (0b100 << 12))
#define LHU     (0b0000011 | (0b101 << 12))

#define SB      (0b0100011 | (0b000 << 12))
#define SH      (0b0100011 | (0b001 << 12))
#define SW      (0b0100011 | (0b010 << 12))

#define ADDI    (0b0010011 | (0b000 << 12))
#define SLTI    (0b0010011 | (0b010 << 12))
#define SLTIU   (0b0010011 | (0b011 << 12))
#define XORI    (0b0010011 | (0b100 << 12))
#define ORI     (0b0010011 | (0b110 << 12))
#define ANDI    (0b0010011 | (0b111 << 12))

#define SLLI    (0b0010011 | (0b001 << 12) | (0b0000000 << 25))
#define SRLI    (0b0010011 | (0b101 << 12) | (0b0000000 << 25))
#define SRAI    (0b0010011 | (0b101 << 12) | (0b0100000 << 25))

#define ADD     (0b0110011 | (0b000 << 12) | (0b0000000 << 25))
#define SUB     (0b0110011 | (0b000 << 12) | (0b0100000 << 25))
#define SLL     (0b0110011 | (0b001 << 12) | (0b0000000 << 25))
#define SLT     (0b0110011 | (0b010 << 12) | (0b0000000 << 25))
#define SLTU    (0b0110011 | (0b011 << 12) | (0b0000000 << 25))
#define XOR     (0b0110011 | (0b100 << 12) | (0b0000000 << 25))
#define SRL     (0b0110011 | (0b101 << 12) | (0b0000000 << 25))
#define SRA     (0b0110011 | (0b101 << 12) | (0b0100000 << 25))
#define OR      (0b0110011 | (0b110 << 12) | (0b0000000 << 25))
#define AND     (0b0110011 | (0b111 << 12) | (0b0000000 << 25))

