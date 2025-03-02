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

        LD      A, 0C3H         ;JP命令
        LD      (0B70EH), A
        LD      HL, PMDHK3
        LD      (0B70FH), HL    ;PMDHK2アドレス書込

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

ATTRHY:
        LD      HL, 0F508H      ;3行目アトリビュートアドレス
        LD      A, 12           ;12文字分一括で設定する
        LD      (HL), A

;=================================================
; プログラムメインループ

LOOP:
        CALL    MUTECHK         ;チャンネルミュート・再生
        JP      LOOP

;=================================================
; サブルーチン
; 現在表示されているリズム音源の各音色を一定時間経過後に
; キーオフ（非表示）する

RHYKYOF:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      HL, RHYTMR      ;タイマーを順に確認
        XOR     A               ;A=0初期化(6までカウント)

RHYKYLP:
        PUSH    AF              ;後続処理のためカウント退避
        LD      A, (HL)         ;タイマーの数値をAレジスタにセット
        SUB     1
        JR      Z, INITTM       ;0になったら非表示・初期化へ
        LD      (HL),A
        INC     HL              ;次のタイマーへ
        POP     AF              ;Aレジスタ復元
        INC     A               ;カウント加算
        CP      6               ;カウントが6まで来たら終了
        JR      Z, ENDTM
        JP      RHYKYLP

INITTM:
        POP     AF              ;カウント用のAを復帰
        LD      (HL), INITTMV   ;タイマー用初期値に変更
        CALL    UNDSPM          ;非表示サブルーチンへ
        CP      6
        JR      Z,ENDTM
        JP      RHYKYLP

ENDTM:
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

;=================================================
; サブルーチン
; タイマーが0になったリズム音源の音色を非表示にする
; 入力: Aレジスタ=非表示にする音色のオフセットアドレス

UNDSPM:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL

        LD      HL, (POSRHY2)   ;表示位置の読み出し
        LD      B, 0
        ADD     A               ;アドレスはDWなのでAを2倍にする
        LD      C, A            ;CにAの値をセット
        ADD     HL, BC          ;アドレスにオフセット値を加算
        EX      DE, HL          ;HL->DEに移す
        LD      HL, SPNOTE      ;HLには空白文字2つをセット
        LDI                     ;1文字目を表示
        LDI                     ;2文字目を表示

        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

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
        CP      10
        JP      RHYTHM
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
        JP      DSPLOOP

RHYTHM:
        PUSH    AF
        CALL    MUPLRHY         ;RHYTHMチャンネルの文字色変更
        POP     AF
        RET


;=================================================
; サブルーチン
; リズムチャンネルのミュート・再生状態に応じて文字色を変更する

MUPLRHY:

        LD      HL, (MUTEFLG)   ;ミュートフラグの状態をHLレジスタにセット
        LD      A, H            ;HレジスタをAレジスタにセット
        AND     04H             ;リズムチャンネルだけを取り出し
        JP      NZ, RYMUTE      ;フラグが1ならミュート

RNTMUTE:
        CALL    SETATT2         ;HLのアドレスにアトリビュートエリアを設定
        LD      A, 0E8H         ;0E8H = 白色
        LD      (HL), A         ;白色を設定
        JP      BYEBYE

RYMUTE:
        CALL    SETATT2         ;HLのアドレスにアトリビュートエリアを設定
        LD      A, 028H         ;028H = 青色
        LD      (HL), A         ;青色を設定

BYEBYE:
       RET

;=================================================
; サブルーチン
; リズム音源の各音色表示のアトリビュート設定
; 出力: HL=アトリビュートエリア属性値変更アドレス

SETATT2:
        LD      HL, (POSRHY2)
        LD      A, L
        ADD     A, 80+1         ;アトリビュートエリア+1
        JR      NC, NOINC2      ;繰り上がり判定
        INC     H               ;繰り上がり分を加算

NOINC2:
        LD      L, A
        RET

;=================================================
; PMD88のサブルーチン（OPNSET44）へのコール直前をフック
; PMD88の元ラベル名: RHYSET
;
; リズム音源の鳴っている音色を判定する

PMDHK3:
        PUSH    AF              ;各種レジスタ保存
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      A, D            ;OPNA音源レジスタCH取得
        CP      10H             ;アドレスが一致しているか
;レジスタCHが10H以外のデータは処理せず抜けさせる
        JP      NZ, HK3RT
        CALL    RHYDSP          ;音色表示サブルーチン

HK3RT:
        POP     HL              ;各種レジスタ復帰
        POP     DE
        POP     BC
        POP     AF

        CALL    0BCA4H          ;元々呼んだサブルーチンへ
	JP      0B711H          ;CALLの直後に戻る

;=================================================
; サブルーチン
; BIT5〜0までを判定して鳴っているか消えているかを表示する
; 入力: Eレジスタ(RHYTHMレジスタ書き込みデータ)

RHYDSP:
        LD      A, E
        LD      B, 6            ;音色は6種類
        RLCA
        LD      DE, (POSRHY)
        LD      HL, RHYDATA     ;状態確認した音色を選択

        JP      C, WDSP3        ;消音処理へ
        AND     A               ;Cフラグクリア

; 発音処理 6種類の音色ごとに鳴りはじめを判定して表示
WDSP2:
        AND     A               ;フラグリセット
        BIT     6, A            ;BIT5→左シフトしたのでBIT6の状態を確認
        JP      Z, NORHY        ;1なら発音している

WDSP22:
        LDI                     ;1文字目を表示
        LDI                     ;2文字目を表示
        PUSH    AF
        PUSH    BC
        LD      A, 6            ;RESETKOの引数(Aレジスタ)をセット
        SUB     B               ;現在のBからA=6-BとなるようAをセット
        CALL    RESETKO         ;リズム音源のキーオフタイマーをリセット
        POP     BC
        POP     AF

WDSP222:
        RLCA                    ;左シフトして次の準備順に調べる
        DJNZ    WDSP2           ;全音色分処理を繰り返す
        JP      RSTPOS3         ;全部終わったら終了

NORHY:
        INC     DE
        INC     DE
        INC     HL
        INC     HL
        JP      WDSP222

RSTPOS3:
        LD      DE, (POSRHY)    ;POSNTEの先頭アドレス
        JP      PRHY

WDSP3:
        AND     A               ;フラグリセット
        BIT     6, A
        JP      Z, NORHY3
        LD      HL, SPNOTE

WDSP33:
        LDI                     ;1文字目を表示
        LDI                     ;2文字目を表示

WDSP333:
        RLCA                    ;左シフトして次の準備順に調べる
        DJNZ    WDSP3           ;全音色分処理を繰り返す
        JP      RSTPOS3         ;全部終わったら終了

NORHY3:
        INC     DE
        INC     DE
        INC     HL
        INC     HL
        JP      WDSP333

PRHY:
        RET

;=================================================
; サブルーチン
; キーオンのタイミングでキーオフカウンターの初期化を行う

RESETKO:
        PUSH    AF
        PUSH    BC
        PUSH    HL

        LD      HL, RHYTMR
        LD      B, 0
        LD      C, A
        ADD     HL, BC
        LD      (HL), INITTMV

        POP     HL              ;各種レジスタ復帰
        POP     BC
        POP     AF

        RET

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
;       (MUTEFLG)=ミュート状態フラグ(1=ミュート, 0=通常再生)
; 出力: VOLFLAG=1(ミュート状態の場合),0(通常再生の場合)

CHMUTE:
        LD      A, (MUTEFLG)    ;ミュート状態確認
        OR      A               ;フラグが0かチェック
        JP      Z, UNMUTE       ;0なら通常再生処理へ

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
        LD      (IX+VOLPUSH), -63 ;FM音量を最小値に（PMD88の音量範囲は0-63）
        JP      MUCHEND

UNMUTE:
        XOR     A               ;A=0
        LD      (VOLFLAG), A    ;フラグを通常再生に設定
        JP      MUCHEND        ;音量変更せずに終了

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
; PMD88のRHYTHM演奏ルーチン内で音量調整の実装をした
RHYVOL:
        JP      MUCHEND

; CHMUTEで直接MUTEENDにJPした場合はボリューム変更値は0のまま
; PMD88で自動的に次の音量調整値は0になる
; VOLFLAGが1にすることで強制的に次の音量調整値もマイナス最大にする

MUCHEND:
       
        RET

;=================================================
; メインプログラム（サブルーチン）
; キー入力によりチャンネルごとにミュートと再生を切り替える
; キーは押した時と離した時でキーマトリクスから判定する

MUTECHK:

        CALL    RHYKYOF         ;リズム音源キーオフ用タイマー

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
        LD      A, (0BD42H)     ;x68_flag判定(詳細不明)
	OR	A
	JR	NZ, MMHOOK

SSG1:
        LD      A, 6            ;SSG1を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BE46H      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 1
	LD	(PARTB),A
	CALL	PSGMAIN

SSG2:
        LD      A, 7            ;SSG2を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BE71H      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 2
	LD	(PARTB),A
	CALL	PSGMAIN

SSG3:
        LD      A, 8            ;SSG3を選択
        LD      (SELCH), A      ;演奏中のチャンネル
        CALL    SETMP           ;NOWCHMTを設定
	LD	IX, 0BE9CH      ;ワークエリアの指定
	LD	A, 3
	LD	(PARTB),A
	CALL	PSGMAIN

MMHOOK:
        LD      A, 9            ;ADPCMを選択
        LD      (SELCH), A      ;演奏中のチャンネル
        CALL    SETMP           ;NOWCHMTを設定
	LD	IX, 0BEC7H      ;ワークエリアの指定
	CALL	PCMMAIN		;IN "PCMDRV.MAC"

RHYTHMS:
        LD      A, 10           ;RHYTHMを選択
        LD      (SELCH), A      ;演奏中のチャンネル
        CALL    SETMP           ;NOWCHMTを設定
        PUSH    AF
        LD      A, (NOWCHMT)    ;リズムがミュート・再生かチェック
        AND     A
        JP      Z, RHYPLAY
        XOR     A               ;ミュートなら最小音量にセット
        LD      C, 011H         ;OPNA音源 レジスタCH
        CALL    OUT45           ;書き込み
        JP      PLAYRHY

RHYPLAY:
        LD      A, (0BCFH)      ;リズムトータルレベル(rhyvol)を取得
        LD      C, 011H         ;OPNA音源 レジスタCH
        CALL    OUT45           ;書き込み

PLAYRHY:
        POP     AF              ;Aレジスタ復元
	LD	IX, 0BEF1H      ;ワークエリアの指定
	CALL	RHYMAIN

FM1:
        LD      A, 0            ;FM1を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BD5CH      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 1
	LD	(PARTB),A
	CALL	FMMAIN

FM2:
        LD      A, 1            ;FM2を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BD83H      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 2
	LD	(PARTB),A
	CALL	FMMAIN

FM3:
        LD      A, 2            ;FM3を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BDAAH      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 3
	LD	(PARTB),A
	CALL	FMMAIN

CSEL46:
	CALL	SEL46

FM4:
        LD      A, 3            ;FM4を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BDD1H      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 1
	LD	(PARTB),A
	CALL	FMMAIN

FM5:
        LD      A, 4            ;FM5を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BDF8H      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 2
	LD	(PARTB),A
	CALL	FMMAIN

FM6:
        LD      A, 5            ;FM6を選択
        LD      (SELCH), A      ;演奏中のチャンネル
	LD	IX, 0BE1FH      ;ワークエリアの指定
        CALL    SETMP           ;NOWCHMTを設定
	LD	A, 3
	LD	(PARTB),A
	CALL	FMMAIN

CHEND:
        JP      0AAE2H
;=================================================
; サブルーチン
; リズム音源のトータルボリューム制御用
; 

OUT45:
        PUSH    AF
O45P0:
        IN      A, (044H)
        RLCA
        JR      C, O45P0
        LD      A, C

O45P1:
        OUT     (044H), A       ;Cレジスタの内容を044Hへ
        LD      A, (0)          ;ウェイト用
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
        PUSH    DE              ;DEのアドレスチェック
        EX      DE, HL          ;DEからHLにデータをセット
        AND     A               ;Cフラグをリセット
        SBC     HL, BC          ;現在のアドレスと終端アドレスを比較
        POP     DE
        POP     BC
        JR      Z, RSTPOS2      ;同じであれば位置をリセット
	LD	HL, (WRKPTR2)   ;現在のワークポインタのアドレスをHLレジスタにセット
	INC	HL              ;アドレスを2加算して
	INC	HL
	LD	(WRKPTR2), HL   ;アドレスをワークアドレスに戻す
        RET

RSTPOS2:
        LD      HL, 0F440H      ;POSNTEの最初のアドレスをセットして
        LD      (POSNTE), HL    ;音名の表示位置をリセットするをリセットする

RSTWRK2:
	LD	HL, WRKADR2	;FM1 FNUMの最初のワークアドレスをセットして
        LD      (WRKPTR2), HL	;ワークポインタをリセットする
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
        LD      HL, (WRKPTR2)   ;SSG音名のワークポインタをセット
        LD      E, (HL)         ;DEにワークポインタのアドレスが指す値をセット
        INC     HL
        LD      D, (HL)		;TONEは上位4bit+下位8bitの12bit必要
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
        CALL    PTOPDW          ;(HL)->DE,HL+=2をする
	LD	(FNMPTR), HL    ;
	EX	DE, HL		;HLは比較する音名の数値
	POP	DE		;DEは現在取得した音名の数値
        AND     A               ;Cフラグをリセット
        SBC     HL, DE          ;HLとDEを比較
	LD	HL, (FNMPTR)
        JP      Z, NEXISTS      ;HLとDEが同じならTONEの音名が特定
        INC     A               ;音名カウンタを加算
        CP      96              ;96まで来たかチェック
        JR      NZ, GETNTES     ;まだであれば繰り返し
        JP      NZERO           ;96までに特定できなければ音名は無し

NEXISTS:
        LD      B,0             ;オクターブ用カウンタ初期化
DIV12:
        SUB     12              ;Aから12引く
        JR      C, MINUS        ;Cフラグ立てば12より少ない
        JR      Z, ZEROS        ;Zフラグ立てばちょうど0=空白
        INC     B               ;12より大きければ1オクターブ加算
        JP      DIV12           ;繰り返し

MINUS:
        ADD     A, 12           ;一旦引いた12を足して
        JP      SETOCTS         ;オクターブセットへ分岐

ZEROS:
        LD      A, B            ;オクターブ情報をAレジスタにせっと
        CP      0               ;0かチェックして
        JP      Z, NZERO        ;0ならばそれは空白、それ以外ならオクターブ有り

SETOCTS:
        PUSH    AF
        LD      A, B            ;B:オクターブ(0~7)
        LD      (OCTAVE), A     ;現在のオクターブ情報をセット
        POP     AF              ;A:現在の音名(0~11)
        LD      B, A            ;音名がある場合Bレジスタに音名データをセット
        JP      NEXIST          ;音名

;=================================================
; サブルーチン
; 音名表示のアトリビュート設定
; 出力: HL=アトリビュートエリア属性値変更アドレス

SETATTR:
        LD      HL, (POSNTE)
        LD      A, L
        ADD     A, 80+1         ;アトリビュートエリア+1
        JR      NC, NOINC       ;繰り上がり判定
        INC     H               ;繰り上がり分を加算

NOINC:
        LD      L, A            ;(繰り上がらない場合そのまま)Lレジスタにセット
        RET

;=================================================
; サブルーチン
; 1/2行目のDBデータを1文字ずつ表示させる

BTDSP:
        LD      HL, (MUTEFLG)   ;全チャンネルのミュートフラグをHLレジスタにセット

BTLOOP:
        CP      0               ;A = 現在の演奏チャンネル用カウンタをチェック
        JR      Z, ISMP         ;0ならミュートフラグのチェックへ
        DEC     A               ;Aを減算
        SRL     H               ;HLを左シフト
        RR      L               ;LレジスタのBIT0に次チャンネルのフラグをセット
        JP      BTLOOP

ISMP:
        LD      A, L            ;LレジスタをAレジスタにセット
        AND     01H             ;現在の演奏チャンネルがミュートか調べる
        JP      NZ, ISMUTE      ;フラグが1ならミュート

NOTMUTE:
        CALL    SETATTR         ;HLのアドレスにアトリビュートエリアを設定
        LD      A, 0E8H         ;0E8H = 白色
        LD      (HL), A         ;白色を設定
        JP      DRAW

ISMUTE:
        CALL    SETATTR         ;HLのアドレスにアトリビュートエリアを設定
        LD      A, 028H         ;028H = 青色
        LD      (HL), A         ;青色を設定

DRAW:
	LD	HL, (WRKPTR)    ;現在のワークポインタのアドレスをHLにセット
        CALL    PTOPDW          ;HL=HL+2, DE=(HL)するサブルーチンを使用する
	LD	(WRKPTR), HL    ;次のアドレスをワークポインタに保存
	EX	DE, HL          ;DEのアドレスをHLに移動
        LD      DE, (POSCNT)    ;DEにキーオンカウントの表示位置を指定
        LD      A, (HL)
        LD      B, A            ;2文字分のデータをBレジスタに一時退避
        RRCA                    ;4BIT分の右シフトを行う
        RRCA
        RRCA
        RRCA
        AND     00FH            ;上位4BITの値を取得
        CALL    NUMCHK          ;文字が0~9かA~Fかで処理を替えて
        LD      (DE),A          ;上位ビットを画面に表示する
        LD      A, B            ;退避させたデータを再びAレジスタにセット
        AND     00FH            ;下位4BITの値を取得
        CALL    NUMCHK          ;文字が0~9かA~Fかで処理を替えて
        INC     DE              ;表示位置を1つ右へずらして
        LD      (DE), A         ;下位ビットを画面に表示する
	INC	DE              ;次の表示のため1つ右にずらしておく
	LD	(POSCNT), DE    ;その座標をPOSCNTに保存する

KONCHK:
	PUSH	BC              ;BCレジスタを退避させる
	LD	BC, 0F3DCH	;10CH表示させた後の表示位置アドレス
	PUSH	DE              
	EX	DE, HL
	AND	A               ;Cフラグをリセット
	SBC	HL, BC          ;現在のアドレス-最終CH表示後アドレス
	POP	DE              ;退避レジスタを復帰
	POP	BC
	JR	Z, RSTPOS       ;最終CH表示後アドレスなら表示位置をリセット
	RET                     ;まだ大丈夫ならこのCALLから復帰させる

RSTPOS:
	LD	HL, 0F3C8H      ;1行目の表示位置をリセット
	LD	(POSCNT), HL

RSTWRK:
	LD	HL, WRKADR      ;ワークアドレスのリセット
	LD	(WRKPTR), HL
	RET

NUMCHK:
        SUB     10              ;0~9かをチェック
        JR      NC, ATOF        ;Cフラグで判断する
        ADD     A, '0'+10       ;最初に10だけ引いたので元に戻す
        RET

ATOF:
        ADD     A, 'A'          ;A-Fの場合Aの値に'A'だけ加算するとA~Fで表示される
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
WRKPTR3:DW      0
FNMPTR: DW      0
FNMTMP:	DW      0
NOTEPTR:DW      0
RHYPTR: DW      0
OCTAVE: DB      0
POSCNT: DW      0F3C8H          ;キーオンカウント表示位置
POSNTE: DW      0F440H          ;音名表示位置
POSRHY: DW      0F4B8H          ;リズム表示位置
POSRHY2:DW      0F4B8H          ;
MUTEFLG:DW      0               ;PLAY(0)/MUTE(1) 11CH分
NOWCHMT:DB      0               ;演奏中のチャンネルがミュート・再生か

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

RHYDATA:DB      'RM'            ;BIT5
        DB      'TM'            ;BIT4
        DB      'HH'            ;BIT3
        DB      'CY'            ;BIT2
        DB      'SD'            ;BIT1
        DB      'BD'            ;BIT0

INITTMV:EQU     80

; キーオフタイマー
RHYTMR: DB      INITTMV         ;BIT5 リムショット
        DB      INITTMV         ;BIT4 タムタム
        DB      INITTMV         ;BIT3 ハイハット
        DB      INITTMV         ;BIT2 シンバル
        DB      INITTMV         ;BIT1 スネア
        DB      INITTMV         ;BIT0 バスドラ


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