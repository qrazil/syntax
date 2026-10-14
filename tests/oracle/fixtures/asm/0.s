// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build ppc64 || ppc64le

#include "textflag.h"

// See memclrNoHeapPointers Go doc for important implementation constraints.

// func memclrNoHeapPointers(ptr unsafe.Pointer, n uintptr)
TEXT runtime·memclrNoHeapPointers<ABIInternal>(SB), NOSPLIT|NOFRAME, $0-16
	// R3 = ptr
	// R4 = n

	// Determine if there are doublewords to clear
check:
	ANDCC $7, R4, R5  // R5: leftover bytes to clear
	SRD   $3, R4, R6  // R6: double words to clear
	CMP   R6, $0, CR1 // CR1[EQ] set if no double words

	BC    12, 6, nozerolarge // only single bytes
	CMP   R4, $512
	BLT   under512           // special case for < 512
	ANDCC $127, R3, R8       // check for 128 alignment of address
	BEQ   zero512setup

	ANDCC $7, R3, R15
	BEQ   zero512xsetup // at least 8 byte aligned

	// zero bytes up to 8 byte alignment

	ANDCC $1, R3, R15 // check for byte alignment
	BEQ   byte2
	MOVB  R0, 0(R3)   // zero 1 byte
	ADD   $1, R3      // bump ptr by 1
	ADD   $-1, R4

byte2:
	ANDCC $2, R3, R15 // check for 2 byte alignment
	BEQ   byte4
	MOVH  R0, 0(R3)   // zero 2 bytes
	ADD   $2, R3      // bump ptr by 2
	ADD   $-2, R4

byte4:
	ANDCC $4, R3, R15   // check for 4 byte alignment
	BEQ   zero512xsetup
	MOVW  R0, 0(R3)     // zero 4 bytes
	ADD   $4, R3        // bump ptr by 4
	ADD   $-4, R4
	BR    zero512xsetup // ptr should now be 8 byte aligned

under512:
	SRDCC $3, R6, R7  // 64 byte chunks?
	XXLXOR VS32, VS32, VS32 // clear VS32 (V0)
	BEQ   lt64gt8

	// Prepare to clear 64 bytes at a time.

zero64setup:
	DCBTST (R3)             // prepare data cache
	MOVD   R7, CTR          // number of 64 byte chunks
	MOVD   $16, R8
	MOVD   $32, R16
	MOVD   $48, R17

zero64:
	STXVD2X VS32, (R3+R0)   // store 16 bytes
	STXVD2X VS32, (R3+R8)
	STXVD2X VS32, (R3+R16)
	STXVD2X VS32, (R3+R17)
	ADD     $64, R3
	ADD     $-64, R4
	BDNZ    zero64          // dec ctr, br zero64 if ctr not 0
	SRDCC   $3, R4, R6	// remaining doublewords
	BEQ     nozerolarge

lt64gt8:
	CMP	R4, $32
	BLT	lt32gt8
	MOVD	$16, R8
	STXVD2X	VS32, (R3+R0)
	STXVD2X	VS32, (R3+R8)
	ADD	$-32, R4
	ADD	$32, R3
lt32gt8:
	CMP	R4, $16
	BLT	lt16gt8
	STXVD2X	VS32, (R3+R0)
	ADD	$16, R3
	ADD	$-16, R4
lt16gt8:
#ifdef GOPPC64_power10
	SLD	$56, R4, R7
	STXVL   V0, R3, R7
	RET
#else
	CMP	R4, $8
	BLT	nozerolarge
	MOVD	R0, 0(R3)
	ADD	$8, R3
	ADD	$-8, R4
#endif
nozerolarge:
	ANDCC $7, R4, R5 // any remaining bytes
	BC    4, 1, LR   // ble lr
#ifdef GOPPC64_power10
	XXLXOR  VS32, VS32, VS32 // clear VS32 (V0)
	SLD	$56, R5, R7
	STXVL   V0, R3, R7
	RET
#else
	CMP   R5, $4
	BLT   next2
	MOVW  R0, 0(R3)
	ADD   $4, R3
	ADD   $-4, R5
next2:
	CMP   R5, $2
