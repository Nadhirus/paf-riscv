# RISCV

This rv32i core was written by Florian Tarazona and Erwan Glasziou as a university project.
Fiew modificatins were done by myself to formally verify it.


Found bugs:
- no detection of ill instructions
- no pipeline stall on load -> insn that uses the load result
- bad forwardig from MEM to EX stages for JAL and JALR
- JALR clear two last bits

- latch register file
- BGE, BGEU (branch if greater or equal) branched if strictly greater
- AUIPC: not implemented



- LW, JAL, branch trap on address miss alignment
- load followed by a conditional branch 
- trap while stalling
- random memory: if a stall occurs, reading the same address won't give the same result.
  for instruction memory, an instruction can be decoded as ill formed during a stall
  an later become valid. It shouldn't trap then. if the first instr



  a bug on conditional branches introduced an error in JAL:
  no trap was triggered when the branch value miss aligned,
  so the PC could get a 4n+2 value, which would trigger an
  exception if JALed with a 4n+2 value. even if the spec does not
  trap as the resulting pc would be 4-aligned.


observations on the paf core:
- the instruction decode stage does not decode the opcode & func

