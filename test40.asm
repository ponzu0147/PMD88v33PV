        ORG     0C800H

PMD88HK:
        LD      IX, (HK1A)      ;PMD88 PLAY
        LD      (IX), HK1V      ;JP(C3) CMD
        LD      HL, PMDHK1
        LD      A, L
        LD      (IX+1), A       ;PMDHK1 ADDR WRITE
        LD      A, H
        LD      (IX+2), A

        LD      IX, (HK2A)      ;PMD88 VOLPUSHCAL
        LD      (IX), HK2V      ;JP(C3) CMD
        LD      HL, PMDHK2
        LD      A, L
        LD      (IX+1), A       ;PMDHK2 ADDR WRITE
        LD      A, H
        LD      (IX+2), A

        LD      IX, (HK3A)      ;PMD88 VOLSET
        LD      (IX), HK3V      ;JP(C3) CMD
        LD      HL, PMDHK3
        LD      A, L
        LD      (IX+1), A       ;PMDHK2 ADDR WRITE
        LD      A, H
        LD      (IX+2), A

INIT:
        LD      HL, WRKADR      ;FM1 LEN WORK ADR
        LD      (WRKPTR), HL    ;WORK PTR SET
	LD	HL, WRKADR2	;FM1 FNUM WORK ADR
        LD      (WRKPTR2), HL	;WORK PTR 2 SET
        XOR     A               ;INIT A=0 FOR LOOP

LOOP:
        PUSH    AF
        CALL    MUTECHK         ;MUTE/PLAY CH
        POP     AF
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
; HOOK FROM PMD88 VOLUME PUSH CALC SUBROUTINE
; ORG LABEL OF PMD88: VOLPUSH_CAL

PMDHK2:
        PUSH    HL
        LD      HL, (MUTEFLG)   ;MUTEFLG(DW)
        LD      A, (SELCH)      ;NOW PLAYING CH
        CALL    CHCHK

	LD	A, (IX+VOLPUSH)
	OR	A
        POP     HL
	RET	Z
	LD	HL, VOLFLAG     ;FROM PMD88
	DEC	(HL)
	RET	Z
	INC	(HL)
        XOR     A
;	LD	(IX+VOLPUSH), A ;DON'T USE
        INC     A               ;USE v3.7
	RET

;=================================================
; HOOK FROM PMD88 VOLUME PUSH CALC SUBROUTINE
; ORG LABEL OF PMD88: VOLSET

PMDHK3:
;        PUSH    HL
;        LD      HL, (MUTEFLG)   ;MUTEFLG(DW)
;        LD      A, (SELCH)      ;NOW PLAYING CH
;        CALL    CHCHK

        LD      A, (IX+VOLPUSH)
;        POP     HL
        JP      0B97AH          ;RETURN PMD88
;=================================================

CHCHK:
        CP      0               ;CMP SELCH VALUE
        JR      Z, CMPMPCH      ;MUTE OR PLAY?
;        JR      Z, MUCHEND      ;DUMMY JR
        DEC     A               ;GOTO NEXT CH
        SRL     H               ;HL: MUTEFLG
        RR      L               ;1BIT RIGHT SHIFT
        JP      CHCHK

CMPMPCH:
;        LD      A, 0
        LD      (VOLFLAG), A
	LD	(IX+VOLPUSH), 0 ;NORMAL VOL(PLAY)
        LD      A, L
        AND     01H             ;BIT0 COMPARE
	LD	(IX+VOLPUSH), 0 ;NORMAL VOL(PLAY)
        JR      Z, MUCHEND      ;NO MATCH IS PLAY
        LD      A, (SELCH)      ;MUTE CH CHK
        CP      6               ;SSG~RHYTHM SKIP
        JR      C, FMVOL
        JP      MUCHEND
;        JR      Z, SSGVOL
;        CP      7               ;SSG2
;        JR      Z, SSGVOL
;        CP      8               ;SSG3
;        JR      Z, SSGVOL

FMVOL:
        LD      A, 02H          ;FLAG=1 NEXT MUTE
        LD      (VOLFLAG), A    ;MUTE SET
        LD      (IX+VOLPUSH), -127;FM MIN VOL
        JP      MUCHEND

SSGVOL: 
;        LD      A, 00H          ;FLAG=1 NEXT MUTE
;        LD      (VOLFLAG), A    ;MUTE SET
        LD      (IX+VOLPUSH), -15;SSG MIN VOL

MUCHEND:
        RET

;=================================================
; ABOUT MUTE FLAG (DW)
; xxxx x000 0000 0000
; ONLY USE BIT0(FM1) ~ BIT10(RHYTHM)
; x: ALWAYS ZERO
; 0: PLAY CH
; 1: MUTE CH

MUTECHK:
        XOR     A
        PUSH    IY
        LD      IY, MUTEFLG
        IN      A, (006H)       ;KBD MATRIX 0~7
        BIT     0, A            ;KEY 0 PUSHED
        JR      Z, SPLOOP
        BIT     1, A            ;KEY 1 PUSHED
        JR      Z, SPLOOP
        BIT     2, A            ;KEY 2 PUSHED
        JR      Z, SPLOOP
        BIT     3, A            ;KEY 3 PUSHED
        JR      Z, SPLOOP
        BIT     4, A            ;KEY 4 PUSHED
        JR      Z, SPLOOP
        BIT     5, A            ;KEY 5 PUSHED
        JR      Z, SPLOOP
        BIT     6, A            ;KEY 6 PUSHED
        JR      Z, SPLOOP
        BIT     7, A            ;KEY 7 PUSHED
        JR      Z, SPLOOP
        IN      A, (007H)       ;KBD MATRIX 8,9
        BIT     0, A            ;KEY 8 PUSHED
        JR      Z, SPLOOP
        BIT     1, A            ;KEY 9 PUSHED
        JR      Z, SPLOOP
        IN      A, (005H)       ;KBD MATRIX -
        BIT     7, A            ;KEY - PUSHED
        JR      Z, SPLOOP
        JP      MPEND

SPLOOP:
        IN      A, (006H)       ;KBD MATRIX 0~7
        BIT     0, A            ;KEY(0):ADPCM
        JP      Z, ADPCMMP
        BIT     1, A            ;KEY(1):FM1
        JP      Z, FM1MP
        BIT     2, A            ;KEY(2):FM2
        JP      Z, FM2MP
        BIT     3, A            ;KEY(3):FM3
        JP      Z, FM3MP
        BIT     4, A            ;KEY(4):FM4
        JP      Z, FM4MP
        BIT     5, A            ;KEY(5):FM5
        JP      Z, FM5MP
        BIT     6, A            ;KEY(6):FM6
        JP      Z, FM6MP
        BIT     7, A            ;KEY(7):SSG1
        JP      Z, SSG1MP
        IN      A, (007H)       ;KBD MATRIX 8,9
        BIT     0, A            ;KEY(8):SSG2
        JP      Z, SSG2MP
        BIT     1, A            ;KEY(9):SSG3
        JP      Z, SSG3MP
        IN      A, (005H)       ;KBD MATRIX -
        BIT     7, A            ;KEY(-):ADPCM
        JP      Z, RHYMP
        JP      MPEND

ADPCMMP:
        BIT     1, (IY+1)
        JR      Z, SETMPCM
        RES     1, (IY+1)
        JP      MPEND

SETMPCM:
        SET     1, (IY+1)
        JP      MPEND

FM1MP:
        BIT     0, (IY)
        JR      Z, SETMFM1
        RES     0, (IY)
        JP      MPEND

SETMFM1:
        SET     0, (IY)
        JP      MPEND

FM2MP:
        BIT     1, (IY)
        JR      Z, SETMFM2
        RES     1, (IY)
        JP      MPEND

SETMFM2:
        SET     1, (IY)
        JP      MPEND

FM3MP:
        BIT     2, (IY)
        JR      Z, SETMFM3
        RES     2, (IY)
        JP      MPEND

SETMFM3:
        SET     2, (IY)
        JP      MPEND

FM4MP:
        BIT     3, (IY)
        JR      Z, SETMFM4
        RES     3, (IY)
        JP      MPEND

SETMFM4:
        SET     3, (IY)
        JP      MPEND

FM5MP:
        BIT     4, (IY)
        JR      Z, SETMFM5
        RES     4, (IY)
        JP      MPEND

SETMFM5:
        SET     4, (IY)
        JP      MPEND

FM6MP:
        BIT     5, (IY)
        JR      Z, SETMFM6
        RES     5, (IY)
        JP      MPEND

SETMFM6:
        SET     5, (IY)
        JP      MPEND

SSG1MP:
        BIT     6, (IY)
        JR      Z, SETMSG1
        RES     6, (IY)
        JP      MPEND

SETMSG1:
        SET     6, (IY)
        JP      MPEND

SSG2MP:
        BIT     7, (IY)
        JR      Z, SETMSG2
        RES     7, (IY)
        JP      MPEND

SETMSG2:
        SET     7, (IY)
        JP      MPEND

SSG3MP:
        BIT     0, (IY+1)
        JR      Z, SETMSG3
        RES     0, (IY+1)
        JP      MPEND

SETMSG3:
        SET     0, (IY+1)
        JP      MPEND

RHYMP:
        BIT     2, (IY+1)
        JR      Z, SETMRHY
        RES     2, (IY+1)
        JP      MPEND

SETMRHY:
        SET     2, (IY+1)

MPEND:
        POP     IY
        RET

;=================================================
; HOOK FROM PMD88 MUSIC PLAYER MAIN ROUTINE
; ORG LABEL OF PMD88: mmain_opm
; A: PMD88 PLAY CHANNEL DETECTION

PMDHK1:
        LD      A, (0BD42H)
	OR	A
	JR	NZ, MMHOOK

SSG1:
        LD      A, 6            ;SSG1 SELECTED
        LD      (SELCH), A
	LD	IX, 0BE46H
	LD	A, 1
	LD	(PARTB),A
	CALL	PSGMAIN

SSG2:
        LD      A, 7            ;SSG2 SELECTED
        LD      (SELCH), A
	LD	IX, 0BE71H
	LD	A, 2
	LD	(PARTB),A
	CALL	PSGMAIN

SSG3:
        LD      A, 8            ;SSG3 SELECTED
        LD      (SELCH), A
	LD	IX, 0BE9CH
	LD	A, 3
	LD	(PARTB),A
	CALL	PSGMAIN

MMHOOK:
        LD      A, 9            ;ADPCM SELECTED
        LD      (SELCH), A
	LD	IX, 0BEC7H
	CALL	PCMMAIN		; IN "PCMDRV.MAC"

RHYTHM:
        LD      A, 10           ;RHYTHM SELECTED
        LD      (SELCH), A
	LD	IX, 0BEF1H
	CALL	RHYMAIN

FM1:
        LD      A, 0            ;FM1 SELECTED
        LD      (SELCH), A
	LD	IX, 0BD5CH
	LD	A, 1
	LD	(PARTB),A
	CALL	FMMAIN

FM2:
        LD      A, 1            ;FM2 SELECTED
        LD      (SELCH), A
	LD	IX, 0BD83H
	LD	A, 2
	LD	(PARTB),A
	CALL	FMMAIN

FM3:
        LD      A, 2            ;FM3 SELECTED
        LD      (SELCH), A
	LD	IX, 0BDAAH
	LD	A, 3
	LD	(PARTB),A
	CALL	FMMAIN

CSEL46:
	CALL	SEL46

FM4:
        LD      A, 3            ;FM4 SELECTED
        LD      (SELCH), A
	LD	IX, 0BDD1H
	LD	A, 1
	LD	(PARTB),A
	CALL	FMMAIN

FM5:
        LD      A, 4            ;FM5 SELECTED
        LD      (SELCH), A
	LD	IX, 0BDF8H
	LD	A, 2
	LD	(PARTB),A
	CALL	FMMAIN

FM6:
        LD      A, 5            ;FM6 SELECTED
        LD      (SELCH), A
	LD	IX, 0BE1FH
	LD	A, 3
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

SELCH:  DB      0               ;PMD88 SELECTED CH
HK1A:   DW      0AA5FH          ;SOURCE 0AA5CH
HK1V:   EQU     0C3H            ;JP COMMAND
HK2A:   DW      0B9CAH          ;SOURCE 0B9CAH
HK2V:   EQU     0C3H            ;JP COMMAND
HK3A:   DW      0B977H          ;SOURCE 0B977H
HK3V:   EQU     0C3H            ;JP COMMAND
VOLFLAG:EQU     0BD43H          ;PMD88 VOLPUSH_FLAG
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
MUTEFLG:DW      0               ;PLAY(0)/MUTE(1) 11CH

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