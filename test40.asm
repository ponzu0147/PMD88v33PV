        ORG     08800H

;=================================================
; PMD88 元のコードを書換えて自プログラムにフックさせる
; PMD88 V3.3 専用 元は FC88V43 と全く同一のプログラム

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
        LD      (0B70FH), HL    ;PMDHK3アドレス書込

;=================================================
; ワークアドレスのポインタを初期化

INIT:
        LD      HL, WRKADR      ;FM1 LENGワークアドレス
        LD      (WRKPTR), HL    ;WORK PTRをセット
        LD      HL, WRKADR2     ;FM1 FNUMワークアドレス
        LD      (WRKPTR2), HL   ;WORK PTRをセット
        LD      A, 3CH          ; PMD88のデフォルト音量
        LD      (RHYTVOL), A    ; トータルボリューム初期化
        LD      C, 011H
        CALL    OUT45           ; OPNAに反映

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
        LD      (HL), A
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
        JR      Z, ENDTM
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
; 各チャンネルの表示(FM/SSG/PCM/RHYTHM)
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
        CALL    BTDSP           ;キーオフカウント表示
        CALL    GETFNUM         ;FM1〜6の音名表示
        POP     AF
        INC     A
        JP      DSPLOOP

SSG:
        PUSH    AF
        CALL    BTDSP           ;キーオフカウント表示
        CALL    GETTONE         ;PSG1〜3の音名表示
        POP     AF
        INC     A
        JP      DSPLOOP

ADPCM:
        PUSH    AF
        CALL    BTDSP           ;キーオフカウント表示
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
        CP      10H             ;キーオン処理
        JR      Z, RHY_KEYON    ;キーオンならRHYDSPへ
        CP      11H             ;トータルボリューム
        JR      NZ, HK3RT       ;それ以外はスキップ
        LD      A, E            ;MMLデータからの値
        LD      (RHYTVOL), A    ;トータルボリューム更新
        JR      HK3RT
RHY_KEYON:
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
        LD      A, E            ;キーオンデータをAに取得
        LD      B, 6            ;音色は6種類
        RLCA                    ;BIT5をBIT6にシフト
        LD      DE, (POSRHY)    ;表示位置
        LD      HL, RHYDATA     ;音色名テーブル（RM, TM, HH, CY, SD, BD）

RHYDSP_LOOP:
        AND     A               ;フラグリセット
        BIT     6, A            ;BIT6をチェック（シフトされた音色ビット）
        JR      Z, NORHY        ;0なら非発音（スキップ）

        ; 発音中の場合、音色名を表示
        PUSH    AF
        PUSH    BC
        PUSH    HL
        LDI                     ;音色名1文字目を表示
        LDI                     ;音色名2文字目を表示
        LD      A, 6
        SUB     B               ;カウンタからインデックス計算
        CALL    RESETKO         ;キーオフタイマーリセット
        POP     HL
        POP     BC
        POP     AF

NORHY:
        INC     DE              ;次の表示位置
        INC     DE
        INC     HL              ;次の音色名
        INC     HL
        RLCA                    ;次のビットをチェック
        DJNZ    RHYDSP_LOOP     ;6音色分繰り返す

        ; キーオン処理をRHYDATから適用
        LD      A, E            ;元のキーオンデータを復元
        LD      B, 6
        LD      HL, RHYDAT      ;音源データテーブル
RHYDSP_KEYON:
        RRA                     ;右シフトで各ビットをチェック
        JR      NC, SKIP_KEYON  ;ビットが0ならスキップ
        PUSH    AF
        LD      D, (HL)         ;レジスタ番号
        INC     HL
        LD      E, (HL)         ;パン/ボリューム
        INC     HL
        CALL    OUT45           ;パン/ボリューム設定
        LD      D, 10H          ;キーオンレジスタ
        LD      E, (HL)         ;キーオンデータ
        CALL    OUT45           ;キーオン実行
        POP     AF
SKIP_KEYON:
        INC     HL              ;次のデータへ
        INC     HL
        DJNZ    RHYDSP_KEYON    ;6音色分繰り返す

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

        POP     HL
        POP     BC
        POP     AF
        RET

;=================================================
; PMD88のサブルーチン（VOLUME PUSH CALC）をフック
; PMD88の元ラベル名: VOLPUSH_CAL

PMDHK2:
        LD      A, (NOWCHMT)
        CP      0
        CALL    NZ, CHMUTE

        LD      A, (IX+VOLPUSH)
        OR      A
        RET     Z
        LD      HL, VOLFLAG
        DEC     (HL)
        RET     Z
        INC     (HL)
CHKOK:
        LD      A, (NOWCHMT)
        CP      0
        JR      NZ, CHKOUT
        XOR     A
        LD      (IX+VOLPUSH), A
CHKOUT:
        RET

;=================================================
; サブルーチン
; 全チャンネルのミュート・再生のフラグ状態をセットする

SETMP:
        XOR     A
        LD      (NOWCHMT), A
        LD      HL, (MUTEFLG)
        LD      A, (SELCH)

SETLOOP:
        CP      0
        JR      Z, SETCH
        DEC     A
        SRL     H
        RR      L
        JP      SETLOOP

SETCH:
        LD      A, L
        AND     01H
        JR      Z, SETEND
        LD      (NOWCHMT), A

SETEND:
        RET

;=================================================
; サブルーチン
; ミュート状態のあいだボリュームを最小値にし続ける

CHMUTE:
        LD      A, (MUTEFLG)
        OR      A
        JP      Z, UNMUTE

        LD      A, (SELCH)
        CP      0
        JR      Z, FMVOL
        CP      1
        JR      Z, FMVOL
        CP      2
        JR      Z, FMVOL
        CP      3
        JR      Z, FMVOL
        CP      4
        JR      Z, FMVOL
        CP      5
        JR      Z, FMVOL
        CP      6
        JR      Z, SSGVOL
        CP      7
        JR      Z, SSGVOL
        CP      8
        JR      Z, SSGVOL
        CP      9
        JR      Z, PCMVOL
        CP      10
        JR      Z, RHYVOL
        JP      MUCHEND

FMVOL:
        LD      A, 01H
        LD      (VOLFLAG), A
        LD      (IX+VOLPUSH), -63
        JP      MUCHEND

UNMUTE:
        XOR     A
        LD      (VOLFLAG), A
        JP      MUCHEND

SSGVOL:
        LD      A, 01H
        LD      (VOLFLAG), A
        LD      (IX+VOLPUSH), -15
        JP      MUCHEND

PCMVOL:
        LD      A, 01H
        LD      (VOLFLAG), A
        LD      (IX+VOLPUSH), -255
        JP      MUCHEND

RHYVOL:
        LD      A, 01H
        LD      (VOLFLAG), A
        XOR     A
        LD      (0BCFH), A
        LD      C, 011H
        CALL    OUT45
        JP      MUCHEND

MUCHEND:
        RET

;=================================================
; メインプログラム（サブルーチン）
; キー入力によりチャンネルごとにミュートと再生を切り替える

MUTECHK:
        CALL    RHYKYOF

        PUSH    BC
        CALL    DSPCH
        POP     BC

        PUSH    IY
        LD      IY, MUTEFLG

        IN      A, (006H)
        BIT     0, A
        LD      B, 0
        JR      Z, SPLOOP
        BIT     1, A
        LD      B, 1
        JR      Z, SPLOOP
        BIT     2, A
        LD      B, 2
        JR      Z, SPLOOP
        BIT     3, A
        LD      B, 3
        JR      Z, SPLOOP
        BIT     4, A
        LD      B, 4
        JR      Z, SPLOOP
        BIT     5, A
        LD      B, 5
        JR      Z, SPLOOP
        BIT     6, A
        LD      B, 6
        JR      Z, SPLOOP
        BIT     7, A
        LD      B, 7
        JR      Z, SPLOOP
        IN      A, (007H)
        BIT     0, A
        LD      B, 8
        JR      Z, SPLOOP
        BIT     1, A
        LD      B, 9
        JR      Z, SPLOOP
        IN      A, (005H)
        BIT     7, A
        LD      B, 10
        JR      Z, SPLOOP
        POP     IY
        JP      MUTECHK

SPLOOP:
        PUSH    BC
        CALL    DSPCH
        POP     BC

        XOR     A
        CP      B
        JR      Z, RELKY0
        INC     A
        CP      B
        JR      Z, RELKY1
        INC     A
        CP      B
        JR      Z, RELKY2
        INC     A
        CP      B
        JR      Z, RELKY3
        INC     A
        CP      B
        JR      Z, RELKY4
        INC     A
        CP      B
        JR      Z, RELKY5
        INC     A
        CP      B
        JR      Z, RELKY6
        INC     A
        CP      B
        JR      Z, RELKY7
        INC     A
        CP      B
        JR      Z, RELKY8
        INC     A
        CP      B
        JR      Z, RELKY9
        INC     A
        CP      B
        JR      Z, RELKY10
        JP      SPLOOP

RELKY0:
        IN      A, (006H)
        BIT     0, A
        JP      NZ, ADPCMMP
        JP      SPLOOP

RELKY1:
        IN      A, (006H)
        BIT     1, A
        JP      NZ, FM1MP
        JP      SPLOOP

RELKY2:
        IN      A, (006H)
        BIT     2, A
        JP      NZ, FM2MP
        JP      SPLOOP

RELKY3:
        IN      A, (006H)
        BIT     3, A
        JP      NZ, FM3MP
        JP      SPLOOP

RELKY4:
        IN      A, (006H)
        BIT     4, A
        JP      NZ, FM4MP
        JP      SPLOOP

RELKY5:
        IN      A, (006H)
        BIT     5, A
        JP      NZ, FM5MP
        JP      SPLOOP

RELKY6:
        IN      A, (006H)
        BIT     6, A
        JP      NZ, FM6MP
        JP      SPLOOP

RELKY7:
        IN      A, (006H)
        BIT     7, A
        JP      NZ, SSG1MP
        JP      SPLOOP

RELKY8:
        IN      A, (007H)
        BIT     0, A
        JP      NZ, SSG2MP
        JP      SPLOOP

RELKY9:
        IN      A, (007H)
        BIT     1, A
        JP      NZ, SSG3MP
        JP      SPLOOP

RELKY10:
        IN      A, (005H)
        BIT     7, A
        JP      NZ, RHYMP
        JP      SPLOOP

ADPCMMP:
        BIT     1, (IY+1)
        JR      Z, SETMPCM
        RES     1, (IY+1)
        XOR     A
        LD      (VOLFLAG), A
        JP      MPEND

SETMPCM:
        SET     1, (IY+1)
        LD      A, 01H
        LD      (VOLFLAG), A
        LD      IX, 0BEC7H
        LD      (IX+VOLPUSH), -255
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
; PMD88音楽再生メインルーチンをフック

PMDHK1:
        LD      A, (0BD42H)
        OR      A
        JR      NZ, MMHOOK

SSG1:
        LD      A, 6
        LD      (SELCH), A
        LD      IX, 0BE46H
        CALL    SETMP
        LD      A, 1
        LD      (PARTB), A
        CALL    PSGMAIN

SSG2:
        LD      A, 7
        LD      (SELCH), A
        LD      IX, 0BE71H
        CALL    SETMP
        LD      A, 2
        LD      (PARTB), A
        CALL    PSGMAIN

SSG3:
        LD      A, 8
        LD      (SELCH), A
        CALL    SETMP
        LD      IX, 0BE9CH
        LD      A, 3
        LD      (PARTB), A
        CALL    PSGMAIN

MMHOOK:
        LD      A, 9
        LD      (SELCH), A
        CALL    SETMP
        LD      IX, 0BEC7H
        LD      A, (NOWCHMT)
        AND     A
        JP      NZ, ADPCMMUTE
        LD      A, (VOLFLAG)
        AND     A
        JP      NZ, ADPCMSKIP
        CALL    PCMMAIN
        JP      RHYTHMS

ADPCMMUTE:
        LD      (IX+VOLPUSH), -255
        CALL    PCMMAIN
        JP      RHYTHMS

ADPCMSKIP:
        XOR     A
        LD      (VOLFLAG), A
        JP      RHYTHMS

RHYTHMS:
        LD      A, 10
        LD      (SELCH), A
        CALL    SETMP
        PUSH    AF
        LD      A, (NOWCHMT)
        AND     A
        JR      Z, RHYPLAY
        XOR     A
        LD      (0BCFH), A
        LD      C, 011H
        CALL    OUT45
        JR      PLAYRHY

RHYPLAY:
        LD      A, (RHYTVOL)
        LD      (0BCFH), A
        LD      C, 011H
        CALL    OUT45

PLAYRHY:
        POP     AF
        LD      IX, 0BEF1H
        CALL    RHYMAIN

FM1:
        LD      A, 0
        LD      (SELCH), A
        LD      IX, 0BD5CH
        CALL    SETMP
        LD      A, 1
        LD      (PARTB), A
        CALL    FMMAIN

FM2:
        LD      A, 1
        LD      (SELCH), A
        LD      IX, 0BD83H
        CALL    SETMP
        LD      A, 2
        LD      (PARTB), A
        CALL    FMMAIN

FM3:
        LD      A, 2
        LD      (SELCH), A
        LD      IX, 0BDAAH
        CALL    SETMP
        LD      A, 3
        LD      (PARTB), A
        CALL    FMMAIN

CSEL46:
        CALL    SEL46

FM4:
        LD      A, 3
        LD      (SELCH), A
        LD      IX, 0BDD1H
        CALL    SETMP
        LD      A, 1
        LD      (PARTB), A
        CALL    FMMAIN

FM5:
        LD      A, 4
        LD      (SELCH), A
        LD      IX, 0BDF8H
        CALL    SETMP
        LD      A, 2
        LD      (PARTB), A
        CALL    FMMAIN

FM6:
        LD      A, 5
        LD      (SELCH), A
        LD      IX, 0BE1FH
        CALL    SETMP
        LD      A, 3
        LD      (PARTB), A
        CALL    FMMAIN

CHEND:
        JP      0AAE2H

;=================================================
; サブルーチン
; リズム音源のトータルボリューム制御用

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

PTOPDW:
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        INC     HL
        RET

;=================================================
; ワークエリアの音名データと音名テーブルを比較して音名を取得する

GETNOTE:
        PUSH    DE
        CALL    PTOPDW
        LD      (FNMPTR), HL
        EX      DE, HL
        POP     DE
        AND     A
        SBC     HL, DE
        LD      HL, (FNMPTR)
        JR      Z, NEXIST
        DJNZ    GETNOTE

NZERO:
        LD      HL, SPNOTE
        LD      (NOTEPTR), HL
        LD      B, 0
        JP      WDSP

NEXIST:
        LD      HL, NOTE
        LD      A, 12
        SUB     B
        JR      Z, SKIPLP
        SLA     A
        LD      B, A

EXISTLP:
        INC     HL
        DJNZ    EXISTLP

SKIPLP:
        LD      (NOTEPTR), HL

WDSP:
        LD      DE, (POSNTE)
        LD      HL, (NOTEPTR)
        LDI
        LDI
        LD      (POSNTE), DE

NOTECHK:
        PUSH    BC
        LD      BC, 0F454H
        PUSH    DE
        EX      DE, HL
        AND     A
        SBC     HL, BC
        POP     DE
        POP     BC
        JR      Z, RSTPOS2
        LD      HL, (WRKPTR2)
        INC     HL
        INC     HL
        LD      (WRKPTR2), HL
        RET

RSTPOS2:
        LD      HL, 0F440H
        LD      (POSNTE), HL

RSTWRK2:
        LD      HL, WRKADR2
        LD      (WRKPTR2), HL
        RET

;=================================================
; サブルーチン
; ADPCMが鳴っているかはPMD88のワークエリアから取得する

GETAD:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        EX      DE, HL
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        LD      (FNMTMP), HL
        LD      A, E
        AND     A
        JP      Z, NZERO

        LD      HL, ADNOTE
        LD      (NOTEPTR), HL
        LD      B, 0
        JP      WDSP

;=================================================
; サブルーチン
; FNUMの値(11ビット)をPMD88のワークエリアから取得する

GETFNUM:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        EX      DE, HL
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        LD      (FNMTMP), HL
GETOCT:
        LD      A, D
        RRCA
        RRCA
        RRCA
        AND     07H
        LD      (OCTAVE), A
        LD      A, D
        AND     07H
        LD      D, A
        LD      A, E
        AND     A
        JP      Z, NZERO

        LD      B, 12
        LD      HL, FNUMBER
        LD      (FNMPTR), HL
        JP      GETNOTE

;=================================================

GETTONE:
        LD      HL, (WRKPTR2)
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        EX      DE, HL
        LD      E, (HL)
        INC     HL
        LD      D, (HL)
        LD      (FNMTMP), HL
        LD      A, E
        AND     A
        JP      Z, NZERO

        XOR     A
        LD      HL, SSGTP
        LD      (FNMPTR), HL

GETNTES:
        PUSH    DE
        CALL    PTOPDW
        LD      (FNMPTR), HL
        EX      DE, HL
        POP     DE
        AND     A
        SBC     HL, DE
        LD      HL, (FNMPTR)
        JP      Z, NEXISTS
        INC     A
        CP      96
        JR      NZ, GETNTES
        JP      NZERO

NEXISTS:
        LD      B, 0
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
        LD      (OCTAVE), A
        POP     AF
        LD      B, A
        JP      NEXIST

;=================================================
; サブルーチン
; 音名表示のアトリビュート設定

SETATTR:
        LD      HL, (POSNTE)
        LD      A, L
        ADD     A, 80+1
        JR      NC, NOINC
        INC     H

NOINC:
        LD      L, A
        RET

;=================================================
; サブルーチン
; 1/2行目のDBデータを1文字ずつ表示させる

BTDSP:
        LD      HL, (MUTEFLG)

BTLOOP:
        CP      0
        JR      Z, ISMP
        DEC     A
        SRL     H
        RR      L
        JP      BTLOOP

ISMP:
        LD      A, L
        AND     01H
        JP      NZ, ISMUTE

NOTMUTE:
        CALL    SETATTR
        LD      A, 0E8H
        LD      (HL), A
        JP      DRAW

ISMUTE:
        CALL    SETATTR
        LD      A, 028H
        LD      (HL), A

DRAW:
        LD      HL, (WRKPTR)
        CALL    PTOPDW
        LD      (WRKPTR), HL
        EX      DE, HL
        LD      DE, (POSCNT)
        LD      A, (HL)
        LD      B, A
        RRCA
        RRCA
        RRCA
        RRCA
        AND     00FH
        CALL    NUMCHK
        LD      (DE), A
        LD      A, B
        AND     00FH
        CALL    NUMCHK
        INC     DE
        LD      (DE), A
        INC     DE
        LD      (POSCNT), DE

KONCHK:
        PUSH    BC
        LD      BC, 0F3DCH
        PUSH    DE
        EX      DE, HL
        AND     A
        SBC     HL, BC
        POP     DE
        POP     BC
        JR      Z, RSTPOS
        RET

RSTPOS:
        LD      HL, 0F3C8H
        LD      (POSCNT), HL

RSTWRK:
        LD      HL, WRKADR
        LD      (WRKPTR), HL
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
; ワークエリア

SELCH:  DB      0
PCMFLAG:EQU     0AA1EH
VOLFLAG:EQU     0BD43H
PARTB:  EQU     0BD3BH
PSGMAIN:EQU     0B14FH
PCMMAIN:EQU     0AB44H
RHYMAIN:EQU     0B1EFH
FMMAIN: EQU     0B0CFH
SEL46:  EQU     0B0A8H
HK1RT:  EQU     0AAE2H
WRKPTR: DW      0
WRKPTR2:DW      0
WRKPTR3:DW      0
FNMPTR: DW      0
FNMTMP: DW      0
NOTEPTR:DW      0
RHYPTR: DW      0
OCTAVE: DB      0
POSCNT: DW      0F3C8H
POSNTE: DW      0F440H
POSRHY: DW      0F4B8H
POSRHY2:DW      0F4B8H
MUTEFLG:DW      0
NOWCHMT:DB      0
RHYTVOL:DB      03CH

WRKADR: DW      0BD60H
        DW      0BD87H
        DW      0BDAEH
        DW      0BDD5H
        DW      0BDFCH
        DW      0BE23H
        DW      0BE4AH
        DW      0BE75H
        DW      0BEA0H
        DW      0BECBH

WRKADR2:DW      0BD61H
        DW      0BD88H
        DW      0BDAFH
        DW      0BDD6H
        DW      0BDFDH
        DW      0BE24H
        DW      0BE4BH
        DW      0BE76H
        DW      0BEA1H
        DW      0BECCH

FNUMBER:DW      618
        DW      655
        DW      694
        DW      735
        DW      779
        DW      825
        DW      874
        DW      926
        DW      981
        DW      1040
        DW      1102
        DW      1167

SSGTP:  DW      3816
        DW      3602
        DW      3400
        DW      3209
        DW      3029
        DW      2859
        DW      2698
        DW      2547
        DW      2404
        DW      2269
        DW      2142
        DW      2022
        DW      1908
        DW      1801
        DW      1700
        DW      1604
        DW      1514
        DW      1429
        DW      1349
        DW      1273
        DW      1202
        DW      1134
        DW      1071
        DW      1011
        DW      954
        DW      900
        DW      850
        DW      802
        DW      757
        DW      714
        DW      674
        DW      636
        DW      601
        DW      567
        DW      535
        DW      505
        DW      477
        DW      450
        DW      425
        DW      401
        DW      378
        DW      357
        DW      337
        DW      318
        DW      300
        DW      283
        DW      267
        DW      252
        DW      238
        DW      225
        DW      212
        DW      200
        DW      189
        DW      178
        DW      168
        DW      159
        DW      150
        DW      141
        DW      133
        DW      126
        DW      119
        DW      112
        DW      106
        DW      100
        DW      94
        DW      89
        DW      84
        DW      79
        DW      75
        DW      70
        DW      66
        DW      63
        DW      59
        DW      56
        DW      53
        DW      50
        DW      47
        DW      44
        DW      42
        DW      39
        DW      37
        DW      35
        DW      33
        DW      31
        DW      29
        DW      28
        DW      26
        DW      25
        DW      23
        DW      22
        DW      21
        DW      19
        DW      18
        DW      17
        DW      16
        DW      15

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

OCTDATA:DB      'O1'
        DB      'O2'
        DB      'O3'
        DB      'O4'
        DB      'O5'
        DB      'O6'
        DB      'O7'
        DB      'O8'

RHYDATA:DB      'RM'
        DB      'TM'
        DB      'HH'
        DB      'CY'
        DB      'SD'
        DB      'BD'

INITTMV:EQU     80

RHYTMR: DB      INITTMV
        DB      INITTMV
        DB      INITTMV
        DB      INITTMV
        DB      INITTMV
        DB      INITTMV

RHYDAT: DB      18H, 11011111B, 00000001B  ; BD
        DB      19H, 11011111B, 00000010B  ; SD
        DB      1AH, 11011111B, 00000100B  ; CY
        DB      1BH, 10011100B, 10001000B  ; HH
        DB      1CH, 11011111B, 00010000B  ; TM
        DB      1DH, 11010011B, 00100000B  ; RM

;===================================================
; ワークアドレス (PMD88V3.7のソースより BY KAJA)
ADDRESS:    EQU     0
PARTLP:     EQU     2
LENG:       EQU     4
RHYTHML:    EQU     5
FNUM:       EQU     5
DETUNE:     EQU     7
LFODAT:     EQU     9
QDAT:       EQU     11
VOLUME:     EQU     12
SHIFT:      EQU     13
DELAY:      EQU     14
SPEED:      EQU     15
STEP:       EQU     16
TIME:       EQU     17
DELAY2:     EQU     18
SPEED2:     EQU     19
STEP2:      EQU     20
TIME2:      EQU     21
LFOSWI:     EQU     22
VOLPUSH:    EQU     23
PORTANM:    EQU     24
PORTAN2:    EQU     26
PORTAN3:    EQU     28
MDEPTH:     EQU     30
MDSPD:      EQU     31
MDSPD2:     EQU     32
ENVF:       EQU     33
PAT:        EQU     34
PV2:        EQU     35
PR1:        EQU     36
PR2:        EQU     37
PATB:       EQU     38
PR1B:       EQU     39
PR2B:       EQU     40
PENV:       EQU     41
PCMLEN:     EQU     42
ALGO:       EQU     33
SLOT1:      EQU     34
SLOT3:      EQU     35
SLOT2:      EQU     36
SLOT4:      EQU     37
FMPAN:      EQU     38
FMLEN:      EQU     39
SSGPAT:     EQU     42
SSGLEN:     EQU     43