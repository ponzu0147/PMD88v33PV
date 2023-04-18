        ORG     08500H

INIT:
        LD      HL, WRKADR      ;FM1 LEN WORK ADR
        LD      (WRKPTR), HL    ;WORK PTR SET
	LD	HL, WRKADR2	;FM1 FNUM WORK ADR
        LD      (WRKPTR2), HL	;WORK PTR 2 SET
        XOR     A               ;INIT A=0 FOR LOOP

LOOP:
        CP      6               ;6~8:SSG
        JR      Z, SSG
        CP      7
        JR      Z, SSG
        CP      8
        JR      Z, SSG
        CP      9
        JR      Z, ADPCM        ;9:ADPCM
        JP      FM              ;0~5:FM
        JP      LOOP

FM:
        PUSH    AF
        CALL    BTDSP		;LOOP CNT DISP
        CALL    GETFNUM		;FM NOTE DISP
        POP     AF
        INC     A
        JP      LOOP

SSG:
        PUSH    AF
        CALL    BTDSP		;LOOP CNT DISP
	CALL	GETTONE		;SSG NOTE DISP
        POP     AF
        INC     A
        JP      LOOP

ADPCM:
        CALL    BTDSP		;LOOP CNT DISP
;       CALL    GETAPCM         ;ADPCM NOTE DISP
        XOR     A
        JP      LOOP

;=================================================
PTOPDW:
        LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL
        RET

GETNOTE:
	PUSH	DE
        CALL    PTOPDW          ;(HL)->HL DE:DSTRY
	LD	(FNMPTR), HL
	EX	DE, HL		;HL:COMPARE NOTE
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
        LD      BC, 0F452H      ;FM,SSG 18BYTE
        PUSH    DE              ;DE ADDR CHECK
        EX      DE, HL          ;DE->HL
        AND     A               ;RESET C FLAG
        SBC     HL, BC
        POP     DE
        POP     BC
        JR      Z, RSTPOS2
	LD	HL, (WRKPTR2)
	INC	HL
	INC	HL
	LD	(WRKPTR2), HL
        RET

RSTPOS2:
        LD      HL, 0F440H      ;POSNTE FIRST ADR
        LD      (POSNTE), HL   ;POSNTE RESET

RSTWRK2:
	LD	HL, WRKADR2	;FM1 FNUM WORK ADR
        LD      (WRKPTR2), HL	;WORK PTR 2 RESET
	RET
;=================================================
GETFNUM:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)		;FNUM:LWR 11BIT
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
        JP      GETNOTE

;=================================================
GETTONE:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)		;TONE:LWR 12BIT
	EX	DE, HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(FNMTMP), HL
        LD      A, E            ;LWR 8BIT 0 CHK
        AND     A
        JP      Z, NZERO

        LD      A, 0            ;INC CNT TO 96
        LD      HL, SSGTP
	LD	(FNMPTR), HL

GETNTES:
	PUSH	DE
        CALL    PTOPDW          ;(HL)->HL DE:DSTRY
	LD	(FNMPTR), HL
	EX	DE, HL		;HL:CMP NOTE
	POP	DE		;DE:CUR NOTE
        AND     A               ;RESET C FLAG
        SBC     HL, DE
	LD	HL, (FNMPTR)
        JP      Z, NEXISTS
        INC     A
        CP      96
        JR      NZ, GETNTES
        JP      NZERO

NEXISTS:
        LD      B,0
DIV12:
        SUB     12
        JR      C, MINUS
        JR      Z, ZEROS
        INC     B
        JP      DIV12

MINUS:
        ADD     A, 12
        JP      SETOCTS

ZEROS:
        LD      A, B
        CP      0
        JP      Z, NZERO

SETOCTS:
        PUSH    AF
        LD      A, B
        LD      (OCTAVE), A     ;B:OCTAVE(0~7)
        POP     AF              ;A:NOTE(0~11)
        LD      B, A            ;NEXIST NEEDS NOTE
        JP      NEXIST

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
;WORK AREA

WRKPTR: DW      0
WRKPTR2:DW	0
FNMPTR: DW      0
FNMTMP:	DW	0
NOTEPTR:DW      0
OCTAVE: DB      0
POSCNT: DW      0F3C8H          ;DISPLAY COUNTER POS
POSNTE: DW      0F440H          ;DISPLAY NOTE POS

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
        DW      0BE4BH          ;SSG1
        DW      0BE76H          ;SSG2
        DW      0BEA1H          ;SSG3

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
        DW      1167            ;B'

SSGTP:  DW      3816            ;OCT1 C
        DW      3602            ;OCT1 C+
        DW      3400            ;OCT1 D
        DW      3209            ;OCT1 D+
        DW      3029            ;OCT1 E
        DW      2859            ;OCT1 F
        DW      2698            ;OCT1 F+
        DW      2547            ;OCT1 G
        DW      2404            ;OCT1 G+
        DW      2269            ;OCT1 A
        DW      2142            ;OCT1 A+
        DW      2022            ;OCT1 B
        DW      1908            ;OCT2 C
        DW      1801            ;OCT2 C+
        DW      1700            ;OCT2 D
        DW      1604            ;OCT2 D+
        DW      1514            ;OCT2 E
        DW      1429            ;OCT2 F
        DW      1349            ;OCT2 F+
        DW      1273            ;OCT2 G
        DW      1202            ;OCT2 G+
        DW      1134            ;OCT2 A
        DW      1071            ;OCT2 A+
        DW      1011            ;OCT2 B
        DW      954             ;OCT3 C
        DW      900             ;OCT3 C+
        DW      850             ;OCT3 D
        DW      802             ;OCT3 D+
        DW      757             ;OCT3 E
        DW      714             ;OCT3 F
        DW      674             ;OCT3 F+
        DW      636             ;OCT3 G
        DW      601             ;OCT3 G+
        DW      567             ;OCT3 A
        DW      535             ;OCT3 A+
        DW      505             ;OCT3 B
        DW      477             ;OCT4 C
        DW      450             ;OCT4 C+
        DW      425             ;OCT4 D
        DW      401             ;OCT4 D+
        DW      378             ;OCT4 E
        DW      357             ;OCT4 F
        DW      337             ;OCT4 F+
        DW      318             ;OCT4 G
        DW      300             ;OCT4 G+
        DW      283             ;OCT4 A
        DW      267             ;OCT4 A+
        DW      252             ;OCT4 B
        DW      238             ;OCT5 C
        DW      225             ;OCT5 C+
        DW      212             ;OCT5 D
        DW      200             ;OCT5 D+
        DW      189             ;OCT5 E
        DW      178             ;OCT5 F
        DW      168             ;OCT5 F+
        DW      159             ;OCT5 G
        DW      150             ;OCT5 G+
        DW      141             ;OCT5 A
        DW      133             ;OCT5 A+
        DW      126             ;OCT5 B
        DW      119             ;OCT6 C
        DW      112             ;OCT6 C+
        DW      106             ;OCT6 D
        DW      100             ;OCT6 D+
        DW      94              ;OCT6 E
        DW      89              ;OCT6 F
        DW      84              ;OCT6 F+
        DW      79              ;OCT6 G
        DW      75              ;OCT6 G+
        DW      70              ;OCT6 A
        DW      66              ;OCT6 A+
        DW      63              ;OCT6 B
        DW      59              ;OCT7 C
        DW      56              ;OCT7 C+
        DW      53              ;OCT7 D
        DW      50              ;OCT7 D+
        DW      47              ;OCT7 E
        DW      44              ;OCT7 F
        DW      42              ;OCT7 F+
        DW      39              ;OCT7 G
        DW      37              ;OCT7 G+
        DW      35              ;OCT7 A
        DW      33              ;OCT7 A+
        DW      31              ;OCT7 B
        DW      29              ;OCT8 C
        DW      28              ;OCT8 C+
        DW      26              ;OCT8 D
        DW      25              ;OCT8 D+
        DW      23              ;OCT8 E
        DW      22              ;OCT8 F
        DW      21              ;OCT8 F+
        DW      19              ;OCT8 G
        DW      18              ;OCT8 G+
        DW      17              ;OCT8 A
        DW      16              ;OCT8 A+
        DW      15              ;OCT8 B

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

OCTDATA:DB      'o1'
        DB      'o2'
        DB      'o3'
        DB      'o4'
        DB      'o5'
        DB      'o6'
        DB      'o7'
        DB      'o8'

