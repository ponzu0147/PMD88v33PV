        ORG     08800H

;=================================================
; PMD88 元のコードを書換えて自プログラムにフックさせる
; PMD88 v3.3 専用 元は FC88V43 と全く同一のプログラム

PMD88HK:
        LD      A, 0C3H         ;JP命令
        LD      (0AA5FH), A
        LD      HL, PMDHK1
        LD      (0AA60H), HL    ;PMDHK1アドレス書込

        LD      A, 0C3H         ;JP命令
        LD      (0B9CAH), A
        LD      HL, PMDHK2
        LD      (0B9CBH), HL    ;PMDHK2アドレス書込

;=================================================
; ワークアドレスのポインタを初期化

INIT:
        LD      HL, WRKADR      ;FM1 LENGワークアドレス
        LD      (WRKPTR), HL    ;WORK PTRをセット
        LD      HL, WRKADR2     ;FM1 FNUMワークアドレス
        LD      (WRKPTR2), HL	;WORK PTRをセット

;=================================================
; テキスト表示（音名を出す際）のアトリビュートを初期化

ATTINIT:
        LD      HL, 0F490H      ;2行目アトリビュートアドレス
        LD      A, 2

ATTLOOP:
        LD      (HL), A         ;2,4,6,8,10,...,20
        INC     A
        INC     A
        INC     HL
        INC     HL
        CP      22
        JP      NZ, ATTLOOP

;=================================================
; プログラムメインループ

LOOP:
        CALL    MUTECHK         ;チャンネルをミュート・再生
        JP      LOOP

;=================================================
; サブルーチン
; 各チャンネルの表示(FM/SSG/PCM)
; Aレジスタ = 各チャンネル(0〜10)

DSPCH:
        XOR     A

DSPLOOP:
        CP      0
        JR      Z, FM
        CP      1
        JR      Z, FM
        CP      2
        JR      Z, FM
        CP      3
        JR      Z, FM
        CP      4
        JR      Z, FM
        CP      5
        JR      Z, FM
        CP      6
        JR      Z, SSG
        CP      7
        JR      Z, SSG
        CP      8
        JR      Z, SSG
        CP      9
        JR      Z, ADPCM
; RHYTHM の種類表示は現在未実装
;        CP      10
;        JP      RHYTHM
        RET

;=================================================

FM:
        PUSH    AF
        CALL    BTDSP		;キーオフカウント表示
        CALL    GETFNUM		;FM1〜6の音名表示
        POP     AF
        INC     A
        JP      DSPLOOP

SSG:
        PUSH    AF
        CALL    BTDSP		;キーオフカウント表示
	CALL	GETTONE		;PSG1〜3の音名表示
        POP     AF
        INC     A
        JP      DSPLOOP

ADPCM:
        PUSH    AF
        CALL    BTDSP		;キーオフカウント表示
        CALL    GETAD           ;ADPCMの発音表示
        POP     AF
        INC     A
;        JP      DSPLOOP
        RET

RHYTHM:
;        RET

;=================================================
; PMD88のサブルーチン（VOLUME PUSH CALC）をフック
; PMD88の元ラベル名: VOLPUSH_CAL

PMDHK2:
        LD      A, (NOWCHMT)
        CP      0
;現在のチャンネルがミュート状態であれば継続させる
        CALL    NZ, CHMUTE

	LD	A, (IX+VOLPUSH) ;VOLPUSH=0で復帰
	OR	A
	RET	Z
	LD	HL, VOLFLAG     ;PMD88から
	DEC	(HL)
	RET	Z
	INC	(HL)
CHKOK:
        LD      A, (NOWCHMT)
        CP      0
        JR      NZ, CHKOUT
        XOR     A
	LD	(IX+VOLPUSH), A ;VOLPUSH=0をセット
;        INC     A               ;v3.7 で使用？
CHKOUT:
	RET

;=================================================
; サブルーチン
; 全チャンネルのミュート・再生のフラグ状態をセットする
; 出力: (NOWCHMT)= 現在のチャンネルがミュート(1)か
;       再生(0)かをセットする
;
; ミュートフラグ(DW)について
; xxxx x000 0000 0000
; BIT0(FM1) ~ BIT10(RHYTHM)のみ使用
; x: 常に0（未使用）
; 0: チャンネルを演奏
; 1: チャンネルをミュート

SETMP:
        XOR     A
        LD      (NOWCHMT), A    ;NOWCHMTをリセット
        LD      HL, (MUTEFLG)
        LD      A, (SELCH)

SETLOOP:
        CP      0               ;SELCHの値を比較
        JR      Z, SETCH        ;ミュートか再生か
        DEC     A               ;次のチャンネルへ
        SRL     H               ;HL: MUTEFLG
        RR      L               ;HLを1ビット右シフト
        JP      SETLOOP

SETCH:
        LD      A, L
        AND     01H             ;BIT0をチェック
        JR      Z, SETEND       ;Zなら現チャンネルはミュートではない
        LD      (NOWCHMT), A    ;現チャンネルのミュート状態を設定

SETEND:
        RET

;=================================================
; サブルーチン
; ミュート状態のあいだボリュームを最小値にし続ける
; PMD88の1音だけ音量変更を利用してミュートを実装している
; 入力: (SELCH)=現在PMD88が再生しているチャンネル(0〜10)
; 出力: VOLFLAG=1(ミュート状態の場合),0(通常再生の場合)

CHMUTE:
        LD      A, (SELCH)      ;現在の再生チャンネル種別確認
        CP      0               ;FM1
        JR      Z, FMVOL
        CP      1               ;FM2
        JR      Z, FMVOL
        CP      2               ;FM3
        JR      Z, FMVOL
        CP      3               ;FM4
        JR      Z, FMVOL
        CP      4               ;FM5
        JR      Z, FMVOL
        CP      5               ;FM6
        JR      Z, FMVOL
        CP      6               ;SSG1
        JR      Z, SSGVOL
        CP      7               ;SSG2
        JR      Z, SSGVOL
        CP      8               ;SSG3
        JR      Z, SSGVOL
        CP      9               ;ADPCM
        JR      Z, PCMVOL
        CP      10              ;RHYTHM
        JR      Z, RHYVOL
        JP      MUCHEND

FMVOL:
        LD      A, 01H          ;FLAG=1ならミュート
        LD      (VOLFLAG), A    ;フラグをミュートに設定(次回継続)
        LD      (IX+VOLPUSH), -127;最小音量
        JP      MUCHEND

SSGVOL: 
        LD      A, 01H          ;FLAG=1ならミュート
        LD      (VOLFLAG), A    ;フラグをミュートに設定(次回継続)
        LD      (IX+VOLPUSH), -15;最小音量
        JP      MUCHEND

PCMVOL:
        LD      A, 01H          ;FLAG=1ならミュート
        LD      (VOLFLAG), A    ;フラグをミュートに設定(次回継続)
        LD      (IX+VOLPUSH),-255;最小音量
        JP      MUCHEND

; PMD88にRHYTHMの音量調節用ワークエリアは存在しない
; 独自に音量を調整する必要がある（未実装）
RHYVOL:
        LD      A, (NOWCHMT)
        AND     A
        JR      NZ, MUCHEND
        JP      MUCHEND
        LD      A, 10
        LD      H, A
        XOR     A
        LD      L, A
        OUT     (44H), A

; CHMUTEで直接MUTEENDにJPした場合はボリューム変更値は0のまま
; PMD88で自動的に次の音量調整値は0になる
; VOLFLAGが1にすることで強制的に次の音量調整値もマイナス最大にする

MUCHEND:
       
        RET

;=================================================
; メインプログラム（サブルーチン）
; キー入力によりチャンネルごとにミュートと再生を切り替える
; キーは押した時と話した時でキーマトリクスから判定する

MUTECHK:

        PUSH    BC
        CALL    DSPCH           ;パラメータ表示
        POP     BC

        PUSH    IY
        LD      IY, MUTEFLG

        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     0, A            ;"0"キーが押された
        LD      B, 0
        JR      Z, SPLOOP
        BIT     1, A            ;"1"キーが押された
        LD      B, 1
        JR      Z, SPLOOP
        BIT     2, A            ;"2"キーが押された
        LD      B, 2
        JR      Z, SPLOOP
        BIT     3, A            ;"3"キーが押された
        LD      B, 3
        JR      Z, SPLOOP
        BIT     4, A            ;"4"キーが押された
        LD      B, 4
        JR      Z, SPLOOP
        BIT     5, A            ;"5"キーが押された
        LD      B, 5
        JR      Z, SPLOOP
        BIT     6, A            ;"6"キーが押された
        LD      B, 6
        JR      Z, SPLOOP
        BIT     7, A            ;"7"キーが押された
        LD      B, 7
        JR      Z, SPLOOP
        IN      A, (007H)       ;キーマトリクス8,9
        BIT     0, A            ;"8"キーが押された
        LD      B, 8
        JR      Z, SPLOOP
        BIT     1, A            ;"9"キーが押された
        LD      B, 9
        JR      Z, SPLOOP
        IN      A, (005H)       ;キーマトリクス-
        BIT     7, A            ;"-"キーが押された
        LD      B, 10
        JR      Z, SPLOOP
        POP     IY
        JP      MUTECHK

SPLOOP:
        PUSH    BC
        CALL    DSPCH           ;パラメータ表示
        POP     BC

        XOR     A
        CP      B
        JR      Z, RELKY0       ;"0"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY1       ;"1"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY2       ;"2"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY3       ;"3"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY4       ;"4"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY5       ;"5"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY6       ;"6"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY7       ;"7"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY8       ;"8"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY9       ;"9"キーが離された？
        INC     A
        CP      B
        JR      Z, RELKY10      ;"-"キーが離された？
        JP      SPLOOP

RELKY0:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     0, A            ;"0"キーが離された
        JP      NZ, ADPCMMP     ;ADPCMをミュートor再生
        JP      SPLOOP

RELKY1:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     1, A            ;"1"キーが離された
        JP      NZ, FM1MP       ;FM1をミュートor再生
        JP      SPLOOP

RELKY2:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     2, A            ;"2"キーが離された
        JP      NZ, FM2MP       ;FM2をミュートor再生
        JP      SPLOOP

RELKY3:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     3, A            ;"3"キーが離された
        JP      NZ, FM3MP       ;FM3をミュートor再生
        JP      SPLOOP

RELKY4:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     4, A            ;"4"キーが離された
        JP      NZ, FM4MP       ;FM4をミュートor再生
        JP      SPLOOP

RELKY5:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     5, A            ;"5"キーが離された
        JP      NZ, FM5MP       ;FM5をミュートor再生
        JP      SPLOOP

RELKY6:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     6, A            ;"6"キーが離された
        JP      NZ, FM6MP       ;FM6をミュートor再生
        JP      SPLOOP

RELKY7:
        IN      A, (006H)       ;キーマトリクス0〜7
        BIT     7, A            ;"7"キーが離された
        JP      NZ, SSG1MP      ;SSG1をミュートor再生
        JP      SPLOOP

RELKY8:
        IN      A, (007H)       ;キーマトリクス8,9
        BIT     0, A            ;"8"キーが離された
        JP      NZ, SSG2MP      ;SSG2をミュートor再生
        JP      SPLOOP

RELKY9:
        IN      A, (007H)       ;キーマトリクス8,9
        BIT     1, A            ;"9"キーが離された
        JP      NZ, SSG3MP      ;SSG3をミュートor再生
        JP      SPLOOP

RELKY10:
        IN      A, (005H)       ;キーマトリクス-
        BIT     7, A            ;"-"キーが離された
        JP      NZ, RHYMP       ;RHYTHMをミュートor再生
        JP      SPLOOP

ADPCMMP:
        BIT     1, (IY+1)       ;ADPCMミュート
        JR      Z, SETMPCM
        RES     1, (IY+1)
        JP      MPEND

SETMPCM:
        SET     1, (IY+1)       ;ADPCM再生
        JP      MPEND

FM1MP:
        BIT     0, (IY)         ;FM1ミュート
        JR      Z, SETMFM1
        RES     0, (IY)
        JP      MPEND

SETMFM1:
        SET     0, (IY)         ;FM1再生
        JP      MPEND

FM2MP:
        BIT     1, (IY)         ;FM2ミュート
        JR      Z, SETMFM2
        RES     1, (IY)
        JP      MPEND

SETMFM2:
        SET     1, (IY)         ;FM2再生
        JP      MPEND

FM3MP:
        BIT     2, (IY)         ;FM3ミュート
        JR      Z, SETMFM3
        RES     2, (IY)
        JP      MPEND

SETMFM3:
        SET     2, (IY)         ;FM3再生
        JP      MPEND

FM4MP:
        BIT     3, (IY)         ;FM4ミュート
        JR      Z, SETMFM4
        RES     3, (IY)
        JP      MPEND

SETMFM4:
        SET     3, (IY)         ;FM4再生
        JP      MPEND

FM5MP:
        BIT     4, (IY)         ;FM5ミュート
        JR      Z, SETMFM5
        RES     4, (IY)
        JP      MPEND

SETMFM5:
        SET     4, (IY)         ;FM5再生
        JP      MPEND

FM6MP:
        BIT     5, (IY)         ;FM6ミュート
        JR      Z, SETMFM6
        RES     5, (IY)
        JP      MPEND

SETMFM6:
        SET     5, (IY)         ;FM6再生
        JP      MPEND

SSG1MP:
        BIT     6, (IY)         ;SSG1ミュート
        JR      Z, SETMSG1
        RES     6, (IY)
        JP      MPEND

SETMSG1:
        SET     6, (IY)         ;SSG1再生
        JP      MPEND

SSG2MP:
        BIT     7, (IY)         ;SSG2ミュート
        JR      Z, SETMSG2
        RES     7, (IY)
        JP      MPEND

SETMSG2:
        SET     7, (IY)         ;SSG2再生
        JP      MPEND

SSG3MP:
        BIT     0, (IY+1)       ;SSG3ミュート
        JR      Z, SETMSG3
        RES     0, (IY+1)
        JP      MPEND

SETMSG3:
        SET     0, (IY+1)       ;SSG3再生
        JP      MPEND

RHYMP:
        BIT     2, (IY+1)       ;RHYTHMミュート
        JR      Z, SETMRHY
        RES     2, (IY+1)
        JP      MPEND

SETMRHY:
        SET     2, (IY+1)       ;RHYTHM再生

MPEND:
        POP     IY
        RET

;=================================================
; PMD88音楽再生メインルーチンをフック
; 元のラベル名: mmain_opm
; Aレジスタ: PMD88での再生チャンネルを指定
; IXレジスタ: 各チャンネルのPMD88ワークエリアアドレス
; (SELCH): サブルーチンに現在の再生チャンネルを連携
PMDHK1:
        LD      A, (0BD42H)
	OR	A
	JR	NZ, MMHOOK

SSG1:
        LD      A, 6            ;SSG1を選択
        LD      (SELCH), A
	LD	IX, 0BE46H
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 1
	LD	(PARTB),A
	CALL	PSGMAIN

SSG2:
        LD      A, 7            ;SSG2を選択
        LD      (SELCH), A
	LD	IX, 0BE71H
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 2
	LD	(PARTB),A
	CALL	PSGMAIN

SSG3:
        LD      A, 8            ;SSG3を選択
        LD      (SELCH), A
        CALL    SETMP           ;NOWCHMTを設定
	LD	IX, 0BE9CH
	LD	A, 3
	LD	(PARTB),A
	CALL	PSGMAIN

MMHOOK:
        LD      A, 9            ;ADPCMを選択
        LD      (SELCH), A
        CALL    SETMP           ;NOWCHMTを設定
	LD	IX, 0BEC7H
	CALL	PCMMAIN		;IN "PCMDRV.MAC"

RHYTHMS:
        LD      A, 10           ;RHYTHMを選択
        LD      (SELCH), A
        CALL    SETMP           ;NOWCHMTを設定
        PUSH    AF
        LD      A, (NOWCHMT)
        AND     A
        JP      Z, RHYPLAY
        XOR     A
        LD      C, 011H
        CALL    OUT45
        JP      PLAYRHY

RHYPLAY:
        LD      A, 63
        LD      C, 011H
        CALL    OUT45

PLAYRHY:
        POP     AF
	LD	IX, 0BEF1H
	CALL	RHYMAIN

FM1:
        LD      A, 0            ;FM1を選択
        LD      (SELCH), A
	LD	IX, 0BD5CH
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 1
	LD	(PARTB),A
	CALL	FMMAIN

FM2:
        LD      A, 1            ;FM2を選択
        LD      (SELCH), A
	LD	IX, 0BD83H
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 2
	LD	(PARTB),A
	CALL	FMMAIN

FM3:
        LD      A, 2            ;FM3を選択
        LD      (SELCH), A
	LD	IX, 0BDAAH
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 3
	LD	(PARTB),A
	CALL	FMMAIN

CSEL46:
	CALL	SEL46

FM4:
        LD      A, 3            ;FM4を選択
        LD      (SELCH), A
	LD	IX, 0BDD1H
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 1
	LD	(PARTB),A
	CALL	FMMAIN

FM5:
        LD      A, 4            ;FM5を選択
        LD      (SELCH), A
	LD	IX, 0BDF8H
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 2
	LD	(PARTB),A
	CALL	FMMAIN

FM6:
        LD      A, 5            ;FM6を選択
        LD      (SELCH), A
	LD	IX, 0BE1FH
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 3
	LD	(PARTB),A
	CALL	FMMAIN

CHEND:
        JP      0AAE2H
;=================================================
; サブルーチン
; リズム音源の制御
; 

OUT45:
        PUSH    AF
O45P0:
        IN      A, (044H)
        RLCA
        JR      C, O45P0
        LD      A, C

O45P1:
        OUT     (044H), A
        LD      A, (0)
        POP     AF

O45P2:
        OUT     (045H), A
        RET


;=================================================
; サブルーチン
; DW用間接アドレッシング
; 入力: HL=アドレス
; 出力: HL=HL+2, DE=(HL)

PTOPDW:
        LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL
        RET

;=================================================
; ワークエリアの音名データと音名テーブルを比較して音名を取得する

GETNOTE:
	PUSH	DE              ;現在の音名を保存
        CALL    PTOPDW          ;(HL)->DE,HL+=2（次のワークポインタに移動）
	LD	(FNMPTR), HL    ;ワークポインタを更新
	EX	DE, HL		;HL:比較用音名
	POP	DE		;DE:現在の音名
        AND     A               ;Cフラグリセット
        SBC     HL, DE          ;HL=DEのチェック
	LD	HL, (FNMPTR)    ;ワークポインタの値をHLレジスタに復元
        JR      Z, NEXIST       ;HL=DEなら音名が一致した
        DJNZ    GETNOTE         ;Bレジスタ=音名分(12)の減算カウンタ

; 音名が見つからない場合は音名に空白文字を使用する
NZERO:
        LD      HL, SPNOTE      ;半角スペース2文字をHLレジスタに設定
        LD      (NOTEPTR), HL
	LD	B, 0            ;Bレジスタ操作の用途不明（要調査）
        JP      WDSP

; 音名が見つかった
NEXIST:
        LD      HL, NOTE        ;"C "を初期値で設定
        LD      A, 12
        SUB     B
        JR      Z, SKIPLP       ;最初でマッチした場合はスキップ
        SLA     A
        LD      B, A

EXISTLP:
	INC     HL              ;次の音名をセット
	DJNZ    EXISTLP

; 最初の"C "でマッチしたのでワークポインタに値を設定する
SKIPLP:
	LD	(NOTEPTR), HL

; 2バイト(DW)データを2行目に出力させる
WDSP:
        LD      DE, (POSNTE)	;音名出力位置指定
	LD	HL, (NOTEPTR)   ;音名用ワークポインタ
        LDI                     ;1文字目を表示
        LDI                     ;2文字目を表示
        LD      (POSNTE), DE    ;DE+2させた次の位置を保存

NOTECHK:
        PUSH    BC
        LD      BC, 0F454H      ;FM,SSG,ADPCM 20バイト分
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
; サブルーチン
; ADPCMが鳴っているかはPMD88のワークエリアから取得する
; BECCH〜BECDHに値が入っている時が鳴っている

GETAD:
        LD      HL, (WRKPTR2)   ;ADPCMのワークエリアを記録
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
	EX	DE, HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(FNMTMP), HL
        LD      A, E            ;下位8bitが0は存在しない
        AND     A
        JP      Z, NZERO        ;ADPCMは00(音名なし)

; ADPCMのサンプリングにオクターブは関係がないので取得をしない
; 全てのNOTEは"AD"と表示する

        LD      HL, ADNOTE      ;"AD"をHLレジスタに設定
        LD      (NOTEPTR), HL
	LD	B, 0            ;Bレジスタ操作の用途不明（要調査）
        JP      WDSP

;=================================================
; サブルーチン
; FNUMの値(11ビット)をPMD88のワークエリアから取得する
; FNUMはFM1〜6で使われている

GETFNUM:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)		;FNUM:下位8bit+上位3bit
	EX	DE, HL          ;レジスタ交換して戻す
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(FNMTMP), HL    ;FNMTMPに現在のFNUM値が入る
GETOCT:
	LD	A, D
        RRCA                    ;上位8bitのうち上位5bit必要
        RRCA
        RRCA                    ;右シフトで3bit詰める
        AND     07H             ;5bit中3bit必要
        LD      (OCTAVE), A     ;オクターブを取得
        LD      A, D
        AND     07H             ;FNUM上位3bit確認
        LD      D, A
        LD      A, E		;下位8bitが0のFNUMは存在しない
        AND     A
        JP      Z, NZERO        ;FNUMは00(音名なし)

        LD      B, 12           ;1オクターブ(12)分の減算カウント
        LD      HL, FNUMBER
	LD	(FNMPTR), HL
        JP      GETNOTE

;=================================================

GETTONE:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)		;TONEは上位4bit+下位8bit
	EX	DE, HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(FNMTMP), HL
        LD      A, E            ;下位8bitが0のTONEな存在しない
        AND     A
        JP      Z, NZERO

        XOR     A               ;加算カウンタをセット(0〜96)
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
; SUBROUTINE
; SET ATTRIBUTE VALUE

SETATTR:
        LD      HL, (POSNTE)
        LD      A, L
        ADD     A, 80+1         ;ATTR VRAM AREA
        JR      NC, NOINC
        INC     H

NOINC:
        LD      L, A
        RET

;=================================================
; SUBROUTINE
; DISPLAY BYTE DATA

BTDSP:
        LD      HL, (MUTEFLG)   ;MUTEFLG SET

BTLOOP:
        CP      0               ;A = CURRENT CH
        JR      Z, ISMP
        DEC     A
        SRL     H               ;HL RIGHT SHIFT
        RR      L
        JP      BTLOOP

ISMP:
        LD      A, L
        AND     01H             ;MUTEFLG CHECK
        JP      NZ, ISMUTE

NOTMUTE:
        CALL    SETATTR
        LD      A, 0E8H         ;0E8H = WRITE COLOR
        LD      (HL), A         ;WRITE COLOR ATTR SET
        JP      DRAW

ISMUTE:
        CALL    SETATTR
        LD      A, 028H         ;028H = BLUE COLOR
        LD      (HL), A         ;BLUE COLOR ATTR SET

DRAW:
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
        CALL    NUMCHK          ;0~9 or A~F
        LD      (DE),A          ;DISPLAY UPPER
        LD      A, B
        AND     00FH            ;LOWER 4BIT
        CALL    NUMCHK          ;0~9 or A~F
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
	LD	HL, 0F3C8H      ;RST 1ST LINE POS
	LD	(POSCNT), HL

RSTWRK:
	LD	HL, WRKADR      ;RST WRKADR
	LD	(WRKPTR), HL
	RET

NUMCHK:
        SUB     10              ;0~9 CHECK
        JR      NC, ATOF
        ADD     A, '0'+10
        RET

ATOF:
        ADD     A, 'A'          ;A-F CHECK
        RET

;=================================================
; ワークエリア

SELCH:  DB      0               ;PMD88 現在選択中チャンネル
PCMFLAG:EQU     0AA1EH          ;PMD88 PCMFLAG
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
NOWCHMT:DB      0               ;PLAYING CH IS MUTE?

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
        DW      0BECCH          ;ADPCM

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

ADNOTE: DB      'AD'
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
; ワークアドレス (PMD88v3.7のソースより BY KAJA)
;FM/SSG/ADPCM/RHYTHM
ADDRESS:	EQU	0	; 2 演奏中のアドレス
PARTLP: 	EQU	2       ; 2 演奏の戻り先
LENG:		EQU	4       ; 1 残り LENGTH

RHYTHML:        EQU	5

;FM/SSG/ADPCM
FNUM:		EQU	5       ; 2 演奏中の BLOCK/FNUM
DETUNE:		EQU	7       ; 2 デチューン
LFODAT:		EQU	9       ; 2 LFO DATA
QDAT:		EQU	11      ; 1 Q の値
VOLUME:		EQU	12      ; 1 VOLUME
SHIFT:		EQU	13      ; 1 音階シフトの値
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
ALGO:		EQU	33      ; 1 演奏中の音色の ALGO.
SLOT1:		EQU	34      ; 1 SLOT 1 の TL
SLOT3:		EQU	35      ; 1 SLOT 3 の TL
SLOT2:		EQU	36      ; 1 SLOT 2 の TL
SLOT4:		EQU	37      ; 1 SLOT 4 の TL
FMPAN:		EQU	38	; 1 FM PANNING + AMD + PMD

FMLEN:     	EQU	39

;SSG
SSGPAT:		EQU	42      ; 1 PSG PATTERN (TONE/NOISE/MIX)

SSGLEN:    	EQU	43