//https://centraldeatendimento.totvs.com/hc/pt-br/articles/1500004532861-MP-SIGAEST-MATA240-Pontos-de-Entrada-da-rotina-Movimenta%C3%A7%C3%A3o-Simples
//https://tdn.totvs.com/pages/releaseview.action?pageId=236594627
//https://terminaldeinformacao.com/2021/12/02/como-fazer-validacoes-em-um-parambox/
//https://centraldeatendimento.totvs.com/hc/pt-br/articles/360026045651-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Fun%C3%A7%C3%A3o-parambox-gera-erro-em-ponto-de-entrada
//https://centraldeatendimento.totvs.com/hc/pt-br/articles/360018402211-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Manipular-pergunta
//https://terminaldeinformacao.com/2017/12/12/qual-e-diferenca-entre-type-valtype/
#Include "Rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"

User Function M241BUT()
    Local aArea     := FwGetArea()
    Local aButtons  := {}
    aadd(aButtons , {'', {|| u_fimpop()}, 'Importar OP'})
    FwRestArea(aArea)
Return aButtons

User Function fimpop()
    Local aArea     := FwGetArea()
    Local aSf5      := SF5->(FwGetArea())
    Local cDescri   := ""
    Local nX        := 1
    Local nQtEmp    := 0
    Local aPergs    := {}
    Local aEmp      := {}
    Local aMvPar    := {}
    Local cNumOp    := Space(TamSx3("C2_NUM")[1] + TamSx3("C2_ITEM")[1] + TamSx3("C2_SEQUEN")[1])
    Local cOpMsk    := X3Picture("C2_NUM")
    Private oFont1  := TFont():New("Tahoma", 0, 16, .F.,.T.,,,,,,,,,,,)

    // Se a TM estivar em branco ou se não for TM de requisição eu aborto a importação.
    If Empty(AllTrim(CTM)) .OR. !(Posicione("SF5", 1, FwXFilial("SF5") + CTM, "F5_TIPO") $ "R")
        MsgStop("A TM informada precisa ser de requisção","Leitura de Empenho Abortada.")
    ElseIf !(Posicione("SF5", 1, FwXFilial("SF5") + CTM, "F5_ATUEMP") $ "S")
        MsgStop("A TM informada precisa atualizar empenho","Leitura de Empenho Abortada.")
    Else
        // Salvando os parâmetros de pergunta que estão posicionados na rotina.
        While Type("MV_PAR" + StrZero(nX, 2, 0)) != "U"
            aadd(aMvPar, &("MV_PAR" + StrZero(nX, 2, 0)))
            nX++
        EndDo

        aadd(aPergs, {1, "Ordem de Produção", cNumOp    , cOpMsk  , "u_xVld241(@MV_PAR02)" , "SC2OPS"   , ".T.", 80 , .T.})
        aadd(aPergs, {1, "Descrição"        , cDescri   , "@!"    , ".T."                  , ""         , ".F.", 120, .T.})

        If ParamBox(aPergs, "Selecione a Ordem de Produção",, /*bOK*/, /*aButtons*/, /*lCentered*/, /*nPosX*/, /*nPosY*/, /*oDlgWizard*/, /*cLoad*/, .F., .F.)
            Processa({|| fgetemp(MV_PAR01, @aEmp)}, "Analisando empenho da ordem de produção...")

            aEval(aEmp, {|x| x[9] > 0, nQtEmp += x[9],})

            If nQtEmp > 0
                Processa({|| ftelasel(aEmp)}, "Montando tela de seleção...")
            Else    
                MsgStop("Não foram encontrados empenho para essa OP.","Operação abortada.")
            EndIf
        EndIf

        // Restaurando os valores dos parâmetros de pergunta da rotina.
        For nX := 1 to Len(aMvPar)
            &("MV_PAR" + StrZero(nX, 2, 0)) := aMvPar[nX]
        Next nX
    EndIf

    FwRestArea(aSf5)
    FwRestArea(aArea)
Return

User Function xVld241(cDesc)
    Local aArea     := FwGetArea()
    Local aSc2      := SC2->(FwGetArea())
    Local aSb1      := SB1->(FwGetArea())
    Local lRet      := .T.
    Local cProduto  := ""

    SC2->(DbSetOrder(1))
    SC2->(DbGoTop())

    If !SC2->(MsSeek(FwXFilial("SC2") + MV_PAR01))
        lRet := .F.
        MsgAlert("Ordem de Produção não encontrada.", "Atenção.")
    Else 
        cProduto    := SC2->C2_PRODUTO
        cDesc       := Posicione("SB1", 1, FwXFilial("SB1") + cProduto, "B1_DESC")
        
        If !Empty(SC2->C2_DATRF)
            lRet := .F.
            MsgAlert("Ordem de Produção Encerrada, não será possível dar continuidade.", "Atenção.")
        EndIf
    EndIf

    FwRestArea(aSb1)
    FwRestArea(aSc2)
    FwRestArea(aArea)
Return lRet

Static Function fgetemp(cNumOp, aEmp)
    Local aArea  := FwGetArea()
    Local aSd4   := SD4->(FwGetArea())
    Local aSdc   := SDC->(FwGetArea())
    Local aSb1   := SB1->(FwGetArea())

    SD4->(DbSetOrder(2))
    SD4->(DbGoTop())

    SDC->(DbSetOrder(2))
    SDC->(DbGoTop())

    If SD4->(MsSeek(FwXFilial("SD4") + cNumOp))
        While SD4->(!Eof()) .AND. SD4->(D4_FILIAL + D4_OP) == FwXFilial("SD4") + AvKey(cNumOp,"D4_OP")
            If Upper(Posicione("SB1", 1, FwXFilial("SB1") + SD4->D4_COD, "B1_LOCALIZ")) $ "S"
                If SDC->(MsSeek(FwXFilial("SDC") + SD4->D4_COD + SD4->D4_LOCAL + SD4->D4_OP + SD4->D4_TRT + SD4->D4_LOTECTL + SD4->D4_NUMLOTE))
                    While SDC->(!Eof()) .AND. SDC->(DC_FILIAL + DC_PRODUTO + DC_LOCAL + DC_OP + DC_TRT + DC_LOTECTL + DC_NUMLOTE) == SD4->(D4_FILIAL + D4_COD + D4_LOCAL + D4_OP + D4_TRT + D4_LOTECTL + D4_NUMLOTE)
                        If SDC->DC_QUANT > 0
                            aadd(aEmp, {SD4->D4_FILIAL, SD4->D4_COD, SD4->D4_LOCAL, SD4->D4_OP, SD4->D4_TRT, SD4->D4_LOTECTL, SD4->D4_NUMLOTE, SDC->DC_LOCALIZ, SDC->DC_QUANT, Posicione("SB1", 1, FwXFilial("SB1") + SD4->D4_COD, "B1_UM")})
                        EndIf
                        SDC->(DbSkip())
                    EndDo
                EndIf
            Else
                If SD4->D4_QUANT > 0
                    aadd(aEmp, {SD4->D4_FILIAL, SD4->D4_COD, SD4->D4_LOCAL, SD4->D4_OP, SD4->D4_TRT, SD4->D4_LOTECTL, SD4->D4_NUMLOTE, "", SD4->D4_QUANT, Posicione("SB1", 1, FwXFilial("SB1") + SD4->D4_COD, "B1_UM")})
                EndIf
            EndIf
            SD4->(DbSkip())
        EndDo
    EndIf

    FwRestArea(aSb1)
    FwRestArea(aSdc)
    FwRestArea(aSd4)
    FwRestArea(aArea)
Return

Static function ftelasel(aEmp)
    Local aArea         := FwGetArea()
    Local aSb1          := SB1->(FwGetArea())
    Local nX            := 0
    Local aItems        := {"Produto","Lote","Armazem","Quantidade","Endereço"}
    Local nSel          := 0
    Local nSom          := 0
    Local nSelect       := 0
    Private oOk         := LoadBitmap(GetResources(), "LBOK")
    Private oNo         := LoadBitmap(GetResources(), "LBNO")
    Private aLotes      := {}
    Private olbPainel

    // aAdd(aBut,{'RELOAD' ,{ || MsgRun("Selecionando Lotes do Cliente","Aguarde", {|| fvldok()})}, "Atualizar"})
    For nX := 1 To Len(aEmp)
        If aEmp[nX][9] > 0
            aadd(aLotes, {   .F.,;                                                                    // Check
                            aEmp[nX][4],;                                                             // OP
                            aEmp[nX][2],;                                                             // Produto
                            AllTrim(Posicione("SB1", 1, FwXFilial("SB1") + aEmp[nX][2], "B1_DESC")),; // Descrição
                            aEmp[nX][5],;                                                             // TRT
                            aEmp[nX][3],;                                                             // Armazém 
                            aEmp[nX][10],;                                                            // UM
                            aEmp[nX][9],;                                                             // Quantidade
                            aEmp[nX][9],;                                                             // Quantidade Disponível
                            0,;                                                                       // Qtd Selecionada
                            aEmp[nX][6],;                                                             // Lote
                            aEmp[nX][7],;                                                             // Numlote
                            aEmp[nX][8]})                                                             // Endereço
        EndIf
    Next nX
    aSort(aLotes,,,{|x,y| x[3] < y[3]})

    cOpc:= aItems[1]
    @0,0 To 520,920 Dialog oDlg Title "Seleção de Lotes Disponiveis"
    
    // Criacao do objeto de marcacao
    @30,00 ListBox olbPainel Fields ;
    HEADER "","OP","Produto","Descrição","TRT","Armazém","UM","Quantidade","Qtd Disponível","Qtd Selecionada","Lote","Sublote","Endereço";
    Size 452,180 Of oDlg Pixel;
    ColSizes 5, 40, 60, 80, 30, 30, 20, 60, 60, 60, 60, 60, 40; 
    ON DBLCLICK (fselItem("line", @nSel, @nSom))
    
    olbPainel:SetArray(aLotes)
    olbPainel:bLine := {|| { iif(aLotes[olbPainel:nAt][01],oOk,oNo) ,; //Check
                                aLotes[olbPainel:nAT][02]			,; //Op
                                aLotes[olbPainel:nAT][03]			,; //Produto
                                aLotes[olbPainel:nAT][04]			,; //Descrição
                                aLotes[olbPainel:nAT][05]			,; //TRT
                                aLotes[olbPainel:nAT][06]			,; //Armazém
                                aLotes[olbPainel:nAT][07]			,; //UM
                                aLotes[olbPainel:nAT][08]			,; //Quantidade
                                aLotes[olbPainel:nAT][09]			,; //QTD Disponível
                                aLotes[olbPainel:nAT][10]			,; //QTD Selecionada
                                aLotes[olbPainel:nAT][11]           ,; //Lote
                                aLotes[olbPainel:nAT][12]           ,; //Numlote
                                aLotes[olbPainel:nAT][13]           }} //Endereço
                                    
    olbPainel:bHeaderClick := {|| fselItem("all", @nSel, @nSom)}
    oSaySel1    := TSay():New(17  , 0.6, {|| "Itens Selecionados"}             ,,, oFont1, .F., .F., .F., .F.,0        ,,,, .F., .F., .F., .F., .F.)
    oSaySel2    := TSay():New(17  , 6.1, {|| Transform(nSel,"@E 9999999999")}  ,,, oFont1, .F., .F., .F., .F.,16711680 ,,,, .F., .F., .F., .F., .F.)

    oSaySel3    := TSay():New(17.8, 0.6, {|| "Quantidade Total"}               ,,, oFont1, .F., .F., .F., .F.,0        ,,,, .F., .F., .F., .F., .F.)
    oSaySel4    := TSay():New(17.8, 6.6, {|| Transform(nSom,"@E 9999999999")}  ,,, oFont1, .F., .F., .F., .F.,16711680 ,,,, .F., .F., .F., .F., .F.)

    oSaySel5    := TSay():New(17  , 43.2, {|| "Ordem"}                          ,,, oFont1, .F., .F., .F., .F.,0        ,,,, .F., .F., .F., .F., .F.)
    oCombo      := TComboBox():New(230, 345, {|u| iif(PCount() > 0, cOpc:=u, cOpc)}, aItems, 100, 20, oDlg,, {|| fordArr(cOpc)},,,,.T.,,,,,,,,,"cOpc")
    
    Activate MsDialog oDlg Centered On Init EnchoiceBar(oDlg,{|| nOpca := 1, iif(fvldok(@nSelect),feedCols(nSelect),)}, {|| nOpca := 2,oDlg:End()},,/*aBut*/{})

    FwRestArea(aSb1)
    FwRestArea(aArea)
Return

Static Function fselItem(cTipo, nSel, nSom)
    Local nX    := 0
    Local nQtd  := 0

    Do Case
        Case  cTipo == "line"
            If !aLotes[olbPainel:nAt][01] //Se eu estivar marcando a linha.
                If fDigQtd(@nQtd, @nSel) 
                    aLotes[olbPainel:nAt][01] := !aLotes[olbPainel:nAt][01]
                    aLotes[olbPainel:nAt][09] := aLotes[olbPainel:nAt][08] - nQtd
                    aLotes[olbPainel:nAt][10] := nQtd
                    nSom += nQtd
                    nSel++
                EndIf
            Else 
                aLotes[olbPainel:nAt][01] := !aLotes[olbPainel:nAt][01]
                aLotes[olbPainel:nAt][09] := aLotes[olbPainel:nAT][08]
                nSom -= aLotes[olbPainel:nAt][10]
                nSel--
                aLotes[olbPainel:nAt][10] := 0
            EndIf

        Case cTipo == "all"
            nSel := 0
            nSom := 0

            For nX := 1 To Len(olbPainel:aArray)
                olbPainel:nAt := nX
                aLotes[olbPainel:nAt][01] := !aLotes[olbPainel:nAt][01]

                If aLotes[olbPainel:nAt][01]
                    aLotes[olbPainel:nAt][10] := aLotes[olbPainel:nAt][08] 
                    aLotes[olbPainel:nAt][09] := 0
                    nSom += aLotes[olbPainel:nAt][08] 
                    nSel++
                Else
                    aLotes[olbPainel:nAt][09] := aLotes[olbPainel:nAt][08] // Falo que a quantidade disponível é a quantidade total.
                    aLotes[olbPainel:nAT][10] := 0                         // Zerando a quantidade Selecionada.
                Endif
            Next nX
            olbPainel:nAt := 1
    EndCase

    olbPainel:Refresh()  
    oSaySel2:Refresh()
    oSaySel4:Refresh()
Return

Static Function fDigQtd(nQtd, nSel)
    Local aArea     := FwGetArea()
    Local aMvPar    := {}
    Local nX        := 1
    Local aPergs    := {}
    Local cPicture  := X3Picture("D3_QUANT")
    Local lRet      := .T.
    Local nQuant    := aLotes[olbPainel:nAT][09]

    While Type("MV_PAR" + StrZero(nX, 2, 0)) != "U"
        aadd(aMvPar, &("MV_PAR" + StrZero(nX, 2, 0)))
        nX++
    EndDo

    aadd(aPergs, {1, "Quantidade", nQuant, cPicture, "u_fVldQt(@MV_PAR01)","", ".T.", 120, .T.})

    If ParamBox(aPergs, "Digite a Quantidade",, /*bOK*/, /*aButtons*/, /*lCentered*/, /*nPosX*/, /*nPosY*/, /*oDlgWizard*/, /*cLoad*/, .F., .F.)
       nQtd := MV_PAR01
    Else 
        lRet := .F.
    EndIf

    For nX := 1 to Len(aMvPar)
        &("MV_PAR" + StrZero(nX, 2, 0)) := aMvPar[nX]
    Next nX
    FwRestArea(aArea)
Return lRet

User Function fVldQt()
    Local lRet := .T.

    If MV_PAR01 == 0
        lRet := .F.
        aLotes[olbPainel:nAT][01] := .F.
    Elseif MV_PAR01 > aLotes[olbPainel:nAT][08]
        lRet := .F.
        aLotes[olbPainel:nAT][01] := .F.
        MsgStop("A quantidade selecionada não pode ser maior que a quantidade do lote","Atenção.")
    EndIf

Return lRet

Static Function fordArr(cOpc)
    Do Case
        Case cOpc == "Produto"
            aSort(aLotes,,,{|x,y| x[3] < y[3]})
        Case cOpc == "Lote"
            aSort(aLotes,,,{|x,y| x[11] < y[11]})
        Case cOpc == "Armazem"
            aSort(aLotes,,,{|x,y| x[6] < y[6]})
        Case cOpc == "Quantidade"
            aSort(aLotes,,,{|x,y| x[8] < y[8]})
        Case cOpc == "Endereço"
            aSort(aLotes,,,{|x,y| x[13] < y[13]})
    EndCase

    olbPainel:SetArray(aLotes)
    olbPainel:bLine := {|| { iif(aLotes[olbPainel:nAt][01],oOk,oNo) ,; //Check
                                aLotes[olbPainel:nAT][02]			,; //Op
                                aLotes[olbPainel:nAT][03]			,; //Produto
                                aLotes[olbPainel:nAT][04]			,; //Descrição
                                aLotes[olbPainel:nAT][05]			,; //TRT
                                aLotes[olbPainel:nAT][06]			,; //Armazém
                                aLotes[olbPainel:nAT][07]			,; //UM
                                aLotes[olbPainel:nAT][08]			,; //Quantidade
                                aLotes[olbPainel:nAT][09]			,; //QTD Disponível
                                aLotes[olbPainel:nAT][10]			,; //QTD Selecionada
                                aLotes[olbPainel:nAT][11]           ,; //Lote
                                aLotes[olbPainel:nAT][12]           ,; //Numlote
                                aLotes[olbPainel:nAT][13]           }} //Endereço
    olbPainel:Refresh()
Return

Static function feedCols(nSelect)
    Local nPosCod    := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_COD"    })
    Local nPosLocal  := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_LOCAL"  })
    Local nPosOp     := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_OP"     })
    Local nPosTrt    := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_TRT"    })
    Local nPosLote   := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_LOTECTL"})
    Local nPosNuml   := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_NUMLOTE"})
    Local nPosLoca   := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_LOCALIZ"})
    Local nPosQtd    := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_QUANT"  })
    Local nPosUm     := aScan(aHeader, {|x| Upper(AllTrim(x[2])) == "D3_UM"     })
    Local aColVrg    := {}                                                 
    Local nX         := 0
    Local nI         := 0

    For nX := 1 To nSelect
        aadd(aColVrg, fclonaArr()) 
    Next nX
                                                         
    aSize(aCols, 0)                                                                
    aCols := aClone(aColVrg)                                                        

    For nX := 1 to len(aLotes)  
        If aLotes[nX][1]
            nI++
            aCols[nI][nPosCod]      := aLotes[nX][3]
            RunTrigger(2,nI,Nil,,aHeader[nPosCod][2])

            aCols[nI][nPosLocal]    := aLotes[nX][6]
            RunTrigger(2,nI,Nil,,aHeader[nPosLocal][2])

            aCols[nI][nPosOp]       := aLotes[nX][2]
            RunTrigger(2,nI,Nil,,aHeader[nPosOp][2])

            aCols[nI][nPosTrt]      := aLotes[nX][5]
            RunTrigger(2,nI,Nil,,aHeader[nPosTrt][2])

            aCols[nI][nPosLote]     := aLotes[nX][11]
            RunTrigger(2,nI,Nil,,aHeader[nPosLote][2])

            aCols[nI][nPosNuml]     := aLotes[nX][12]
            RunTrigger(2,nI,Nil,,aHeader[nPosNuml][2])

            aCols[nI][nPosLoca]     := aLotes[nX][13]
            RunTrigger(2,nI,Nil,,aHeader[nPosLoca][2])

            aCols[nI][nPosQtd]      := aLotes[nX][10]
            RunTrigger(2,nI,Nil,,aHeader[nPosQtd][2])

            aCols[nI][nPosUm]      := aLotes[nX][7]
            RunTrigger(2,nI,Nil,,aHeader[nPosUm][2])
        EndIf
    Next nX

    oDlg:End()
Return

Static Function fclonaArr()
    Local nX    := 0
    Local aRet  := Array(len(aCols[1]))

    For nX := 1 to Len(aCols[1])
        Do Case
            Case ValType(aCols[1][nX]) == "C"
                aRet[nX] := Space(Len(aCols[1][nX]))
            Case ValType(aCols[1][nX]) == "D"
                aRet[nX] := CToD("  /  /  ")
            Case ValType(aCols[1][nX]) == "N"
                aRet[nX] := 0
            Case ValType(aCols[1][nX]) == "B"
                // iif(aCols[1][nX], aRet[nX] := .T., aRet[nX] := .F.)
                aRet[nX] := .F. // não quero nenhuma linha deletada.
        EndCase
    Next nX
Return aRet

Static Function fvldok(nSelect)
    Local lRet       := .F.
    aEval(aLotes, {|x| iif(x[1],nSelect++,"")})
    
    If nSelect > 0
        lRet := .T.
    Else
        lRet := .F.
        MsgStop("Selecione pelo menos um registro","Atenção") 
    EndIf

Return lRet
