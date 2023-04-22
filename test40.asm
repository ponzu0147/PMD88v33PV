        ORG     08400H

PMD88HK:
        LD      IX, (HK1A)      ;
        LD      (IX), HK1V      ;C3(JP) CMD WRITE
        LD      HL, PMDHK1
        LD      A, L
        LD      (IX+1), A       ;PMDHK1 ADDR WRITE
        LD      A, H
        LD      (IX+2), A

INIT:
        LD      HL, WRKADR      ;FM1 LEN WORK ADR
        LD      (WRKPTR), HL    ;WORK PTR SET
	LD	HL, WRKADR2	;FM1 FNUM WORK ADR
        LD      (WRKPTR2), HL	;WORK PTR 2 SET
        XOR     A               ;INIT A=0 FOR LOOP

LOOP:
;       CALL    MUTECHK
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
;=================================================
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
; ABOUT MUTE FLAG (DW)
; xxxx x000 0000 0000
; ONLY BIT0 IS FM1 ~ BIT10 IS RHYTHM USE
; x: ALWAYS ZERO
; 0: PLAY CH
; 1: MUTE CH

MUTECHK:
        PUSH    HL              ;REGS SAVE
        PUSH    DE
        PUSH    BC
        PUSH    AF

        LD      HL, (MUTEFLG)   ;SET FLAG TO HL
        LD      IX, (WRKADR)    ;WRKADR GET
        LD      (MUTEPTR),IX    ;MUTEPTR SET
        LD      DE, 0
        SBC     HL, DE          ;ALL BIT 0 CHECK
        JR      Z, MUTEEND
        LD      B, 11           ;BIT COUNTER SET

MUTELP:
        PUSH    HL
        LD      A, L
        AND     00000001B       ;0BIT CHECK
        POP     HL
        JR      NZ, MUTECH
        JP      PLAYCH

SHIFTCH:
        SRL     H               ;HL RIGHT SHIFT
        RR      L
        DJNZ    MUTELP

MUTEEND:
        POP     AF              ;REGS RESTORE
        POP     BC
        POP     DE
        POP     HL
        RET                     ;END SUBROUTINE

MUTECH:
        LD      (IX+VOLUME-4), 0;SET MIN VOL
        JP      MUPLCH

PLAYCH:
        LD      (IX+VOLUME-4), 0;SET NORMAL VOL

MUPLCH:
        PUSH    HL
        PUSH    BC
        POP     DE
        EX      DE, HL          ;BC<->HL
        LD      A, 11
        SUB     B               ;FM1:10-10=0
        PUSH    BC
        CP      6               ;6~8:SSG
        JR      Z, SSGPLUS
        CP      7
        JR      Z, SSGPLUS
        CP      8
        JR      Z, SSGPLUS
        CP      9
        JR      Z, PCMPLUS      ;9:ADPCM
        CP      10
        JR      Z, RHYPLUS      ;10:RHYTHM
        LD      BC, FMLEN       ;FMLEN:39
        JP      PLUSADR

SSGPLUS:
        LD      BC, SSGLEN      ;SSGLEN:43
        JP      PLUSADR

PCMPLUS:
        LD      BC, PCMLEN      ;PCMLEN:42
        JP      PLUSADR

RHYPLUS:
        LD      BC, RHYTHML     ;RHYTHML:5

PLUSADR:
        ADD     HL, BC
        LD      (MUTEPTR),HL
        POP     BC
        POP     HL
        JP      SHIFTCH

;=================================================
; HOOK FROM PMD88 MUSIC PLAYER MAIN ROUTINE
PMDHK1:
        LD      IY, MUTEFLG     ;MUTE FLG 11BIT
        LD      A, (0BD42H)
	OR	A
	JR	NZ, MMHOOK

        BIT     6, (IY)         ;SSG1
        JR      NZ, SSG2        ;Z=1 -> MUTE
	LD	IX, 0BE46H
	LD	A,1
	LD	(PARTB),A
	CALL	PSGMAIN

SSG2:
        BIT     7, (IY)         ;SSG2
        JR      NZ, SSG3        ;Z=1 -> MUTE
	LD	IX, 0BE71H
	LD	A,2
	LD	(PARTB),A
	CALL	PSGMAIN

SSG3:
        BIT     0, (IY+1)       ;SSG3
        JR      NZ, MMHOOK      ;Z=1 -> MUTE
	LD	IX, 0BE9CH
	LD	A,3
	LD	(PARTB),A
	CALL	PSGMAIN

MMHOOK:
        BIT     1, (IY+1)       ;ADPCM
        JR      NZ, RHYTHM      ;Z=1 -> MUTE
	LD	IX, 0BEC7H
	CALL	PCMMAIN		; IN "PCMDRV.MAC"

RHYTHM:
        BIT     2, (IY+1)       ;RHYTHM
        JR      NZ, FM1         ;Z=1 -> MUTE
	LD	IX, 0BEF1H
	CALL	RHYMAIN

FM1:
        BIT     0, (IY)         ;FM1
        JR      NZ, FM2         ;Z=1 -> MUTE
	LD	IX, 0BD5CH
	LD	A,1
	LD	(PARTB),A
	CALL	FMMAIN

FM2:
        BIT     1, (IY)         ;FM2
        JR      NZ, FM3         ;Z=1 -> MUTE
	LD	IX, 0BD83H
	LD	A,2
	LD	(PARTB),A
	CALL	FMMAIN

FM3:
        BIT     2, (IY)         ;FM3
        JR      NZ, CSEL46      ;Z=1 -> MUTE
	LD	IX, 0BDAAH
	LD	A,3
	LD	(PARTB),A
	CALL	FMMAIN

CSEL46:
	CALL	SEL46

FM4:
        BIT     3, (IY)         ;FM4
        JR      NZ, FM5         ;Z=1 -> MUTE
	LD	IX, 0BDD1H
	LD	A,1
	LD	(PARTB),A
	CALL	FMMAIN

FM5:
        BIT     4, (IY)         ;FM5
        JR      NZ, FM6         ;Z=1 -> MUTE
	LD	IX, 0BDF8H
	LD	A,2
	LD	(PARTB),A
	CALL	FMMAIN

FM6:
        BIT     5, (IY)         ;FM6
        JR      NZ, CHEND       ;Z=1 -> MUTE
	LD	IX, 0BE1FH
	LD	A,3
	LD	(PARTB),A
	CALL	FMMAIN

CHEND:
        JP      0AAE2H
;=================================================
PTOPDW:
        LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL
        RET

GETNOTE:
	PUSH	DE
        CALL    PTOPDW          ;(HL)->DE.HL+=2
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
        LD      (POSNTE), HL    ;POSNTE RESET

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
        LD      HL, FNUMBER
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

        XOR     A               ;INC CNT TO 96
        LD      HL, SSGTP
	LD	(FNMPTR), HL

GETNTES:
	PUSH	DE
        CALL    PTOPDW          ;(HL)->DE
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
        LD      A, B            ;B:OCTAVE(0~7)
        LD      (OCTAVE), A     
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

HK1A:   DW      0AA5FH          ;SOURCE 0AA5CH
HK1V:   EQU     0C3H            ;JP COMMAND
PARTB:  EQU     0BD3BH          ;PMD88 PARTB
PSGMAIN:EQU     0B14FH          ;PMD88 PSGMAIN
PCMMAIN:EQU     0AB44H          ;PMD88 PCMMAIN
RHYMAIN:EQU     0B1EFH          ;PMD88 RHYTHMMAIN
FMMAIN: EQU     0B0CFH          ;PMD88 FMMAIN
SEL46:  EQU     0B0A8H          ;PMD88 SEL46
HK1RT:  EQU     0AAE2H          ;RETURN ADDR
WRKPTR: DW      0
WRKPTR2:DW      0
FNMPTR: DW      0
FNMTMP:	DW      0
NOTEPTR:DW      0
OCTAVE: DB      0
POSCNT: DW      0F3C8H          ;DISPLAY COUNTER POS
POSNTE: DW      0F440H          ;DISPLAY NOTE POS
MUTEFLG:DW      2               ;PLAY(0)/MUTE(1) 11CH
MUTEPTR:DW      0

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

FNUMBER:DW      618             ;C
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

;===================================================
;ALL PART WORKADRESS (SOURCE FROM PMD88v3.7 BY KAJA)
;FM/SSG/ADPCM/RHYTHM
ADDRESS:	EQU	0	; 2 ´Ý¿³Á­³ É ±ÄÞÚ½
PARTLP: 	EQU	2       ; 2 ´Ý¿³ É ÓÄÞØ»·
LENG:		EQU	4       ; 1 ÉºØ LENGTH

RHYTHML:        EQU	5

;FM/SSG/ADPCM
FNUM:		EQU	5       ; 2 ´Ý¿³Á­³ É BLOCK/FNUM
DETUNE:		EQU	7       ; 2 ÃÞÁ­°Ý
LFODAT:		EQU	9       ; 2 LFO DATA
QDAT:		EQU	11      ; 1 Q É ±À²
VOLUME:		EQU	12      ; 1 VOLUME
SHIFT:		EQU	13      ; 1 µÝ¶² ¼ÌÄ É ±À²
DELAY:		EQU	14      ; 1 LFO	(DELAY) 
SPEED:		EQU	15      ; 1	(SPEED)
STEP:		EQU	16      ; 1	(STEP)
TIME:		EQU	17      ; 1	(TIME)
DELAY2:		EQU	18      ; 1	(DELAY_2)
SPEED2:		EQU	19      ; 1	(SPEED_2)
STEP2:		EQU	20      ; 1	(STEP_2)
TIME2:		EQU	21      ; 1	(TIME_2)
LFOSWI:		EQU	22      ; 1 LFO SWITCH (0=OFF)
VOLPUSH:	EQU	23	; 1 VOLUME PUSH
PORTANM:	EQU	24	; 2 PORTA ADD ALL
PORTAN2:	EQU	26	; 2 PORTA ADD 1LOOP
PORTAN3:	EQU	28	; 2 PORTA ADD AMARI
MDEPTH:		EQU	30	; 1 M DEPTH
MDSPD:		EQU	31	; 1 M SPEED
MDSPD2:		EQU	32	; 1 M SPEED_2

;SSG/ADPCM
ENVF:		EQU	33      ; 1 PSG ENV. (START_FLAG)
PAT:		EQU	34      ; 1	(AT)
PV2:		EQU	35      ; 1	(V2)
PR1:		EQU	36      ; 1	(R1)
PR2:		EQU	37      ; 1	(R2)
PATB:		EQU	38	; 1	(AT_B)
PR1B:		EQU	39      ; 1	(R1_B)
PR2B:		EQU	40      ; 1	(R2_B)
PENV:		EQU	41      ; 1	(VOLUME +-)

PCMLEN:    	EQU	42

;FM
ALGO:		EQU	33      ; 1 ´Ý¿³Á­³ È²Û É ALGO.
SLOT1:		EQU	34      ; 1 SLOT 1 É TL
SLOT3:		EQU	35      ; 1 SLOT 3 É TL
SLOT2:		EQU	36      ; 1 SLOT 2 É TL
SLOT4:		EQU	37      ; 1 SLOT 4 É TL
FMPAN:		EQU	38	; 1 FM PANNING + AMD + PMD

FMLEN:     	EQU	39

;SSG
SSGPAT:		EQU	42      ; 1 PSG PATTERN (TONE/NOISE/MIX)

SSGLEN:    	EQU	43
