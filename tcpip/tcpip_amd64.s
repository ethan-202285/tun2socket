#include "textflag.h"

DATA endian_swap_mask<>+0(SB)/8, $0x607040502030001
DATA endian_swap_mask<>+8(SB)/8, $0xE0F0C0D0A0B0809
DATA endian_swap_mask<>+16(SB)/8, $0x607040502030001
DATA endian_swap_mask<>+24(SB)/8, $0xE0F0C0D0A0B0809
GLOBL endian_swap_mask<>(SB), RODATA, $32

// func sumAsmAvx2(data unsafe.Pointer, length uintptr) uintptr
//
// args (8 bytes aligned):
//   data   unsafe.Pointer - 8 bytes - 0 offset
//   length uintptr        - 8 bytes - 8 offset
//   result uintptr        - 8 bytes - 16 offset
#define PDATA   AX
#define LENGTH  CX
#define RESULT  BX
TEXT ·sumAsmAvx2(SB),NOSPLIT,$0-24
    MOVQ data+0(FP), PDATA
    MOVQ length+8(FP), LENGTH
    XORQ RESULT, RESULT

#define VSUM             Y0
#define ENDIAN_SWAP_MASK Y1
BEGIN:
    VMOVDQU endian_swap_mask<>(SB), ENDIAN_SWAP_MASK
    VPXOR VSUM, VSUM, VSUM

#define LOADED_0 Y2
#define LOADED_1 Y3
#define LOADED_2 Y4
#define LOADED_3 Y5
BATCH_64:
    CMPQ LENGTH, $64
    JB BATCH_32
    VPMOVZXWD (PDATA), LOADED_0
    VPMOVZXWD 16(PDATA), LOADED_1
    VPMOVZXWD 32(PDATA), LOADED_2
    VPMOVZXWD 48(PDATA), LOADED_3
    VPSHUFB ENDIAN_SWAP_MASK, LOADED_0, LOADED_0
    VPSHUFB ENDIAN_SWAP_MASK, LOADED_1, LOADED_1
    VPSHUFB ENDIAN_SWAP_MASK, LOADED_2, LOADED_2
    VPSHUFB ENDIAN_SWAP_MASK, LOADED_3, LOADED_3
    VPADDD LOADED_0, VSUM, VSUM
    VPADDD LOADED_1, VSUM, VSUM
    VPADDD LOADED_2, VSUM, VSUM
    VPADDD LOADED_3, VSUM, VSUM
    ADDQ $-64, LENGTH
    ADDQ $64, PDATA
    JMP BATCH_64
#undef LOADED_0
#undef LOADED_1
#undef LOADED_2
#undef LOADED_3

#define LOADED_0 Y2
#define LOADED_1 Y3
BATCH_32:
    CMPQ LENGTH, $32
    JB BATCH_16
    VPMOVZXWD (PDATA), LOADED_0
    VPMOVZXWD 16(PDATA), LOADED_1
    VPSHUFB ENDIAN_SWAP_MASK, LOADED_0, LOADED_0
    VPSHUFB ENDIAN_SWAP_MASK, LOADED_1, LOADED_1
    VPADDD LOADED_0, VSUM, VSUM
    VPADDD LOADED_1, VSUM, VSUM
    ADDQ $-32, LENGTH
    ADDQ $32, PDATA
    JMP BATCH_32
#undef LOADED_0
#undef LOADED_1

#define LOADED Y2
BATCH_16:
    CMPQ LENGTH, $16
    JB COLLECT
    VPMOVZXWD (PDATA), LOADED
    VPSHUFB ENDIAN_SWAP_MASK, LOADED, LOADED
    VPADDD LOADED, VSUM, VSUM
    ADDQ $-16, LENGTH
    ADDQ $16, PDATA
    JMP BATCH_16
#undef LOADED

#define EXTRACTED Y2
#define EXTRACTED_128 X2
#define TEMP_64 DX
COLLECT:
    VEXTRACTI128 $0, VSUM, EXTRACTED_128
    VPEXTRD $0, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VPEXTRD $1, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VPEXTRD $2, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VPEXTRD $3, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VEXTRACTI128 $1, VSUM, EXTRACTED_128
    VPEXTRD $0, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VPEXTRD $1, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VPEXTRD $2, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
    VPEXTRD $3, EXTRACTED_128, TEMP_64
    ADDL TEMP_64, RESULT
#undef EXTRACTED
#undef EXTRACTED_128
#undef TEMP_64

#define TEMP DX
#define TEMP2 SI
BATCH_2:
    CMPQ LENGTH, $2
    JB BATCH_1
    XORQ TEMP, TEMP
    MOVW (PDATA), TEMP
    MOVQ TEMP, TEMP2
    SHRW $8, TEMP2
    SHLW $8, TEMP
    ORW TEMP2, TEMP
    ADDL TEMP, RESULT
    ADDQ $-2, LENGTH
    ADDQ $2, PDATA
    JMP BATCH_2
#undef TEMP

#define TEMP DX
BATCH_1:
    CMPQ LENGTH, $0
    JZ RETURN
    MOVB (PDATA), TEMP
    SHLW $8, TEMP
    ADDL TEMP, RESULT
#undef TEMP

RETURN:
    MOVQ RESULT, result+16(FP)
    RET