        ORG     08600H

INIT:
        LD      HL, WRKADR      ;FM1 LEN WORK ADR
        LD      (WRKPTR), HL    ;WORK PTR SET
	LD	HL, WRKADR2	;FM1 FNUM WORK ADR
        LD      (WRKPTR2), HL	;WORK PTR 2 SET

LOOP:
        CALL    BTDSP		;LOOP CNT DISP
        CALL    GETFNUM		;FM NOTE DISP
;	CALL	GETTONE		;SSG NOTE DISP
        JP      LOOP

;=================================================
;SUBROUTINES

PTOPDW:
        LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL
        RET

;=================================================
BTDSP:
	LD	HL, (WRKPTR)
        CALL    PTOPDW          ;(HL)->HL DE:DSTRY
	LD	(WRKPTR), HL
	EX	DE, HL
        LD      DE, (POSCNT)    ;LPCNT DISP POS
        LD      A, (HL)
        LD      B, A
        RRCA                    ;4BIT RIGHT SHIFT
        RRCA
        RRCA
        RRCA
        AND     00FH            ;UPPER 4BIT
        CALL    NUMCHK
        LD      (DE),A          ;DISPLAY UPPER
        LD      A, B
        AND     00FH            ;LOWER 4BIT
        CALL    NUMCHK
        INC     DE
        LD      (DE), A         ;DISPLAY LOWER
	INC	DE
	LD	(POSCNT), DE

KONCHK:
	PUSH	BC
	LD	BC, 0F3DCH	;ALL PART 10CH
	PUSH	DE
	EX	DE, HL
	AND	A
	SBC	HL, BC
	POP	DE
	POP	BC
	JR	Z, RSTPOS
	RET

;=================================================

RSTPOS:
	LD	HL, 0F3C8H
	LD	(POSCNT), HL

RSTWRK:
	LD	HL, WRKADR
	LD	(WRKPTR), HL
	RET

NUMCHK:
        SUB     10
        JR      NC, ATOF
        ADD     A, '0'+10
        RET

ATOF:
        ADD     A, 'A'
        RET

;=================================================

GETFNUM:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)		;DE:OCT:5,FNUM:11
	EX	DE, HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(FNMTMP), HL
GETOCT:
	LD	A, D
        RRCA
        RRCA
        RRCA
        AND     07H
        LD      (OCTAVE), A     ;GET OCT NUM
        LD      A, D
        AND     07H             ;UPR 5BIT CUT
        LD      D, A
        LD      A, E		;LWR 8BIT 0 CHK
        AND     A
        JR      Z, NZERO

        LD      B, 12           ;DEC CNT TO 0
        LD      HL, FNUM
	LD	(FNMPTR), HL

GETNOTE:
	PUSH	DE
        CALL    PTOPDW          ;(HL)->HL DE:DSTRY
	LD	(FNMPTR), HL
	EX	DE, HL		;HL:CMP NOTE
	POP	DE		;DE:CUR NOTE
        AND     A               ;CARRY RESET
        SBC     HL, DE
	LD	HL, (FNMPTR)
        JR      Z, NEXIST
        DJNZ    GETNOTE

NZERO:
        LD      HL, SPNOTE
        LD      (NOTEPTR), HL
	LD	B, 0
        JP      WDSP

;=================================================

NEXIST:
        LD      HL, NOTE
        LD      A, 12
        SUB     B
        JR      Z, SKIPLP       ;B=0 HIT & SKIP
        SLA     A
        LD      B, A

EXISTLP:
	INC     HL
	DJNZ    EXISTLP

SKIPLP:
	LD	(NOTEPTR), HL

WDSP:
        LD      DE, (POSNTE)	;NOTE DISP POS
	LD	HL, (NOTEPTR)
        LDI                     ;DISPLAY UPPER
        LDI                     ;DISPLAY LOWER
        LD      (POSNTE), DE

NOTECHK:
        PUSH    BC
        LD      BC, 0F44CH      ;FM1~6 12BYTE
        PUSH    DE              ;DE ADDR CHECK
        EX      DE, HL          ;DE->HL
        AND     A               ;RESET Z FLAG
        SBC     HL, BC
        POP     DE
        POP     BC
        JR      Z, RSTPOS2
	LD	HL, (WRKPTR2)
	INC	HL
	INC	HL
	LD	(WRKPTR2), HL
        RET

;=================================================

RSTPOS2:
        LD      HL, 0F440H      ;POSNTE FIRST ADR
        LD      (POSNTE), HL    ;POSNTE RESET

RSTWRK2:
	LD	HL, WRKADR2	;FM1 FNUM WORK ADR
        LD      (WRKPTR2), HL	;WORK PTR 2 RESET
	RET

;=================================================
;WORK AREA

WRKPTR: DW      0
WRKPTR2:DW	0
FNMPTR: DW      0
FNMTMP:	DW	0
NOTEPTR:DW      0
OCTAVE: DB      0
POSCNT: DW      0F3C8H          ;DISPLAY COUNTER LINE
POSNTE: DW      0F440H          ;DISPLAY NOTE LINE

WRKADR: DW      0BD60H          ;FM1
        DW      0BD87H          ;FM2
        DW      0BDAEH          ;FM3
        DW      0BDD5H          ;FM4
        DW      0BDFCH          ;FM5
        DW      0BE23H          ;FM6
        DW      0BE4AH          ;SSG1
        DW      0BE75H          ;SSG2
        DW      0BEA0H          ;SSG3
        DW      0BECBH          ;ADPCM

WRKADR2:DW      0BD61H          ;FM1
        DW      0BD88H          ;FM2
        DW      0BDAFH          ;FM3
        DW      0BDD6H          ;FM4
        DW      0BDFDH          ;FM5
        DW      0BE24H          ;FM6

FNUM:   DW      618             ;C
        DW      655             ;C+
        DW      694             ;D
        DW      735             ;D+
        DW      779             ;E
        DW      825             ;F
        DW      874             ;F+
        DW      926             ;G
        DW      981             ;G+
        DW      1040            ;A
        DW      1102            ;A+
        DW      1167            ;B

SPNOTE: DB      '  '
NOTE:   DB      'C '
        DB      'C+'
        DB      'D '
        DB      'D+'
        DB      'E '
        DB      'F '
        DB      'F+'
        DB      'G '
        DB      'G+'
        DB      'A '
        DB      'A+'
        DB      'B '
