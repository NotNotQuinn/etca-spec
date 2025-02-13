# General design

- 16bit word size
- 8 16bit registers
- 4 flags set upon (some) ALU operations: Zero (`Z`), Negative (`N`), Carry (`C`), Overflow (`V`)
- CPU Execution starts at address 0x8000

# Base Instructions

This is a group of 16bit fixed width instructions. The motivation for the chosen instructions is to be both complete and
easy to build in game.

The highest two bits of the first byte are a format marker:

- `00` this is a computation operation between two registers
- `01` this is a computation operation between a register and an immediate
- `10` this is a (conditional) jump instruction
- `11` this is a variable length instruction and reserved for extensions

# Overview

| First byte    | Second Byte  | Comment                                  |
|:--------------|:-------------|:-----------------------------------------|
| `00 01 CCCC`  | `RRR RRR 00` | 2 register computation                   |
| `00 SS CCCC`  | `RRR RRR ??` | when `SS != 01`, reserved for extensions |
| `00 01 CCCC`  | `RRR RRR ??` | when `?? != 00`, reserved for extensions |
| `00 01 11??`  | `RRR RRR ??` | reserved for extensions                  |
| `01 01 CCCC`  | `RRR IIIII`  | immediate and 1 register computation     |
| `01 SS CCCC`  | `RRR IIIII`  | when `SS != 01`, reserved for extensions |
| `10 0 D CCCC` | `DDDDDDDD`   | (conditional) relative jump instruction  |
| `10 1 ?????`  | `?????????`  | reserved for extension                   |
| `11 ??????`   | `?????????`  | reserved for extensions                  |

| Symbol | Meaning                      |
|--------|------------------------------|
| C      | opcode bit                   |
| R      | register id                  |
| I      | immediate                    |
| D      | displacement                 |
| S      | size (res.d)                 |
| ?      | reserved for unknown purpose |

### Execution of Reserved Instructions

Execution of a reserved instruction is undefined behavior. A future extension will change this to "the CPU must trigger a specific interrupt."


## Computation Instructions

Both computation formats share a lot of similarities. For both the first byte has the structure `0x SS CCCC`.

- `SS` is a size marker and reserved for extensions. For the base instructions this should always be `01`
- `CCCC` is a 4bit opcode deciding which operation to execute. This can be an ALU or a memory load/store instruction

### 2 Register Computation

The second byte has the format `AAA BBB 00` where `AAA` and `BBB` are references to registers. `AAA` is the destination register and left source register. `BBB` is the right source register. The only exception is the RSUB instruction where `AAA` and `BBB` are swapped for the purpose of being source registers.

### Immediate Computation

The second byte has the format `RRR IIIII`, where the 5bit immediate acts as operand `B`. The immediate is sign extended for operations 0-7 and operation 9. The immediate is zero extended for operation 8 and operations 10-15. While interleaving of signed and unsigned immediate at the border of the 2 sections seems unusual at first glance, it's done to make decoding hardware simpler.

### Opcodes

TODO: This is a baseline, very much still floating

| `CCCC` | NAME            | Operation                          | Flags  | Comment     |
|--------|-----------------|------------------------------------|--------|-------------|
| `0000` | `ADD`           | `A ← A + B`                        | `ZNCV` |             |
| `0001` | `SUB`           | `A ← A - B`                        | `ZNCV` |             |
| `0010` | `RSUB`          | `A ← B - A`                        | `ZNCV` | (1)         |
| `0011` | `CMP`           | `_ ← A - B`                        | `ZNCV` | (2)         |
| `0100` | `OR`            | <code>A ← A &#124; B</code>        | `ZN`   | (5)         |
| `0101` | `XOR`           | `A ← A ^ B`                        | `ZN`   | (5)         |
| `0110` | `AND`           | `A ← A & B`                        | `ZN`   | (5)         |
| `0111` | `TEST`          | `_ ← A & B`                        | `ZN`   | (2) (5)     |
| `1000` | `MOVZ`          | `A ← B`                            | None   | (7)         |
| `1001` | `MOV` or `MOVS` | `A ← B`                            | None   | (8)         |
| `1010` | `LOAD`          | `A ← MEM[B]`                       | None   |             |
| `1011` | `STORE`         | `MEM[B] ← A`                       | None   | (2)         |
| `1100` | `SLO`           | <code>A ← (A << 5) &#124; B</code> | None   | (3) (6)     |
| `1101` |                 |                                    |        | reserved    |
| `1110` | `READCR`        | `A ← CR[B]`                        | None   | (4) (6)     |
| `1111` | `WRITECR`       | `CR[B] ← A`                        | None   | (2) (4) (6) |


1) Enables NEG and NOT to be encoded as `RSUB r, imm`.
2) Placed here for now to ease decoding; `xx11` => do not store result.
3) Designed to allow for building a larger immediate value. To reach a full 16 bit immediate, a 4th `SLO` or an additional `NOT` may be required.
4) Primary intent is that these are used with immediate. Exact assignment of control registers is still floating. At least the the CPU status/extension/feature control registers should be present.
5) The C and V flags are in an undefined state after execution of these instructions. Implementations may do whatever is easiest. An extension may mandate a particular behavior, with good enough reason, but must *not* mandate that the value of these flags after the operation depends on their value before the operation.
6) These instructions do not have a 2 register mode. The corresponding bit patterns (`00 SS 11??`) for the first byte are reserved. This can easily be detected by using similar to 2)
7) This instruction zero extends argument B as if the value read is of the size specified by the SS bits in the instruction (assuming a relevant extension is present)
8) This instruction sign extends argument B as if the value read is of the size specified by the SS bits in the instruction (assuming a relevant extension is present)

#### Control Register Read and Write Instructions

Undefined control registers are reserved and reading from or writing to them is undefined behavior.

| `CRN`  | NAME       | Description                                                                                                                             | Comment |
|--------|------------|-----------------------------------------------------------------------------------------------------------------------------------------|---------|
| `0000` | `CPUID1`   | Reading from this control register puts the first set of available CPU extensions in the destination register. Writing to it is a NOP.  | (1)     |
| `0001` | `CPUID2`   | Reading from this control register puts the second set of available CPU extensions in the destination register. Writing to it is a NOP. | (1)     |
| `0010` | `FEAT`     | Reading from this control register puts the available CPU features in the destination register. Writing to it is a NOP.                 | (2)     |

1) CPUID uses a bitfield to specify the available extensions. A value of 0 means no extensions are available.
2) FEAT uses a bitfield to specify the available features. A value of 0 means no features are available.

## Memory Semantics

Unaligned memory accesses are undefined behavior. A memory access is unaligned if the address modulus the read/write width is not equal to zero. The read/write width is defined by the SS bits, which for the base ISA corresponds to a read/write width of 2 bytes.

All IO is memory mapped

### Separation of Program ROM and RAM

Aside from program rom starting at address 0x8000, there are no requirements for how the memory address space is layed out. For ease of implementation, this spec does NOT require program memory to be accessible with the load and store instructions nor does it require that RAM be executable. Loads and stores of program memory are undefined behavior. Executing from RAM is undefined behavior. Future extensions will change this behavior

## Flag Semantics

Flags conceptually maintain these values. A future, more rigorous specification of this standard will include a detailed description of affected flags for every instruction individually.

1) The `Z` flag indicates that the result was zero.
2) The `N` flag indicates that the result, interpreted as a 2's complement number, was negative.
3) The `C` flag describes whether an additive instruction caused a carry, or a subtractive computation caused a borrow. The concept of "borrow" is exactly the same as in long-hand decimal subtraction the way you might do it on paper. The flag is set if the subtraction would borrow out of the next most significant bit. A borrow happens precisely when the corresponding addition does _not_ carry. In other words, in order to subtract, you (a) complement the B input, (b) set the carry in, (c) set C to the inverse of the carryout.
4) The `V` flag indicates that the operation caused overflow. This means that storing the result in the destination register caused a loss of precision.

## Jump Instructions

Here the first byte has the format `10 0 D CCCC` where `D` fills the high byte of the displacement. `CCCC` is the condition to check. The second byte is a single 8bit immediate representing the low byte of the displacement. This combined 9 bit displacement (sign extended to 16 bits) is added to the base address of the current instruction and stored in the program counter.

### Conditions


| `CCCC` | NAME                    | Flags                            | Comment |
|--------|-------------------------|----------------------------------|---------|
| `0000` | Zero/Equal              | `Z`                              |         |
| `0001` | Not zero/Not equal      | `~Z`                             |         |
| `0010` | Negative                | `N`                              |         |
| `0011` | Not Negative            | `~N`                             |         |
| `0100` | Carry/Below             | `C`                              |         |
| `0101` | No carry/Above or equal | `~C`                             |         |
| `0110` | Overflow                | `V`                              |         |
| `0111` | No Overflow             | `~V`                             |         |
| `1000` | below or equal          | <code> C &#124; Z</code>         |         |
| `1001` | above                   | <code> ~(C &#124; Z) </code>     |         |
| `1010` | less                    | `N ≠ V`                          |         |
| `1011` | greater or equal        | `N = V`                          |         |
| `1100` | less or equal           | <code> Z &#124; (N ≠ V) </code>  |         |
| `1101` | greater                 | <code> ~Z &amp; (N = V) </code>  |         |
| `1110` | always                  |                                  |         |
| `1111` | never                   |                                  | (1)     |

1) Only a displacement of 0 is considered canonical for this instruction. Non-zero displacements may be overloaded to act differently in future extensions. Overloads of these displacements _must_ require NOP as an acceptable behavior for the overload on implementations that do not implement the extension.
