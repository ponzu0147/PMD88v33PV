        ORG     08600H

START:
        LD      HL, WRKADR      ;FM1 LEN WORK ADR
        LD      (WRKPTR), HL    ;WORK PTR SET
        LD      DE, (POSCNT)    ;FM1 DISPLAY POS
        LD      C,  00AH        ;10CH

LOOP:
        PUSH    DE
        LD      HL, (WRKPTR)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        INC     HL
        LD      (WRKPTR), HL
        EX      DE, HL
        POP     DE
        PUSH    BC
        CALL    BTDSP
        CALL    FSTART
        POP     BC
        DEC     C
        JR      Z, START
        JP      LOOP

BTDSP:
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
        INC     DE              ;NEXT NUMBER
        RET

NUMCHK:
        SUB     10
        JR      NC, ATOF
        ADD     A, '0'+10
        RET

ATOF:
        ADD     A, 'A'
        RET

WDSP:
        LD      DE, (POSNTE)
        LD      A, (HL)
        LD      (DE), A         ;DISPLAY UPPER
        INC     DE
        INC     HL
        LD      A, (HL)
        LD      (DE), A         ;DISPLAY LOWER
        INC     DE              ;NEXT NUMBER
        LD      (POSNTE), DE
        JP      CCHK

FSTART:
        INC     HL              ;TARGET=WRKADR+1
        LD      (FNMPTR), HL

FNMAIN:
        LD      HL, (FNMPTR)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        LD      A, D
        RRCA
        RRCA
        RRCA
        AND     07H
        LD      (OCTAVE), A     ;GET OCT NUM
        LD      A, D
        AND     07H             ;UPR 5BIT CUT
        LD      D, A
        INC     HL
        LD      A, E
        CP      0
        JR      NZ, NSTART
        JP      NZERO

CCHK:
        PUSH    BC
        LD      BC, 0F44CH      ;FM1~6 12BYTE
        AND     A               ;RESET Z FLAG
        PUSH    DE              ;DE ADDR CHECK
        EX      DE, HL          ;DE->HL
        SBC     HL, BC
        POP     DE
        POP     BC
        JR      Z, RSTC
        RET

RSTC:
        LD      A, 040H
        LD      L, A
        LD      A, 0F4H
        LD      H, A
        LD      (POSNTE), HL
        RET

NSTART:
        LD      B, 12           ;DEC CNT TO 0
        LD      HL, FNUM
        LD      (FNMPTR), HL
NLOOP:
        PUSH    DE
        LD      HL, (FNMPTR)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        INC     HL
        LD      (FNMPTR), HL
        EX      DE, HL
        POP     DE
        PUSH    HL
        AND     A               ;CARRY RESET
        SBC     HL, DE
        POP     HL
        JR      Z, NEXIST
        DJNZ    NLOOP
        JP      NZERO

NZERO:
        LD      HL, SPNOTE
        LD      (NTEPTR), HL
        CALL    WDSP
        LD      B, 0
        JP      WDSP

NEXIST:
        LD      HL, NOTE
        LD      A, 12
        SUB     B
        JR      Z, NOLP         ;B=0 HIT
        SLA     A
        LD      B, A

EXLP:
        INC     HL
        DJNZ    EXLP

NOLP:
        LD      (NTEPTR), HL
        JP      WDSP

;WORK AREA
WRKPTR: DW      0
FNMPTR: DW      0
NTEPTR: DW      0
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