#Include "Totvs.ch"
#Include "FWMVCDef.ch"
#Include "Topconn.ch"
#Include 'Protheus.ch'

User Function Diagnest()
    Local aArea         := FwGetArea()

    Private aAuxil      := {;
                            {"Ok", "Ok"}                ,;  // 01 - Mark
                            {"Filial", "B1_FILIAL"}     ,;  // 02 - Filial
                            {"Codigo", "B1_COD"}        ,;  // 03 - Produto
                            {"Descricao", "B1_DESC"}    ,;  // 04 - Descricao
                            {"Lote", "B1_RASTRO"}       ,;  // 05 - Rastro
                            {"Endereco", "B1_LOCALIZ"}  ,;  // 06 - Endereco
                            {"Armazem", "B2_LOCAL"}     ,;  // 07 - Armazem
                            {"Saldo", "B2_QATU"}        ,;  // 08 - Quantidade
                            {"CM", "B2_CM1"}            ,;  // 09 - Custo Médio
                            {"Valor", "B2_VATU1"}       ;   // 10 - Valor
                           }

    Private aPesquisa   := {}
    Private aCampos     := {}
    Private aColunas    := {}
    Private aFields     := {}
    Private cAlias      := GetNextAlias()
    Private oTempTable  := Nil
    Private oMarkBrowse := Nil

    //Adiciona os indices para pesquisar
    /*
        [n,1] Título da pesquisa
        [n,2,n,1] LookUp
        [n,2,n,2] Tipo de dados
        [n,2,n,3] Tamanho
        [n,2,n,4] Decimal
        [n,2,n,5] Título do campo
        [n,2,n,6] Máscara
        [n,2,n,7] Nome Físico do campo - Opcional - é ajustado no programa
        [n,3] Ordem da pesquisa
        [n,4] Exibe na pesquisa
    */
    aAdd(aPesquisa, {"Filial + Codigo"  , {{"", TamSx3(aAuxil[3][2])[3]   , TamSx3(aAuxil[3][2])[1] , TamSx3(aAuxil[3][2])[2] , "Codigo"    , X3Picture(aAuxil[3][2])}}})
    aAdd(aPesquisa, {"Filial + Armazém" , {{"", TamSx3(aAuxil[7][2])[3]   , TamSx3(aAuxil[7][2])[1] , TamSx3(aAuxil[7][2])[2] , "Armazem"   , X3Picture(aAuxil[7][2])}}})

    // Adicionando valores em aCampos e aFields (FwTemporaryTable) e aColunas(FwMarkBrowse).
    xIniVars() 

    oTempTable := FwTemporaryTable():New(cAlias)
    oTempTable:SetFields(aCampos)
    oTempTable:AddIndex("1", {aAuxil[2][1], aAuxil[3][1]}) // Filial + Codigo
    oTempTable:AddIndex("2", {aAuxil[2][1], aAuxil[7][1]}) // Filial + Armazém
    oTempTable:AddIndex("3", {aAuxil[2][1], aAuxil[10][1]}) // Filial + Valor
    oTempTable:Create()

    // Alimentando tabela temporária
    xFeedTmp()
    (cAlias)->(DbSetOrder(3))
    OrdDescend(3, cValToChar(3), .T.)
    (cAlias)->(DbGoTop())

    oMarkBrowse := FwMarkBrowse():New()
    oMarkBrowse:SetFields(aFields)
    oMarkBrowse:SetAlias(cAlias)
    oMarkBrowse:SetTemporary(.T.)
    oMarkBrowse:DisableDetails()
    oMarkBrowse:SetDescription("Diagnest - Análise")
    oMarkBrowse:DisableReport()
    oMarkBrowse:SetFieldMark(aColunas[1][1]) // "Ok"
    oMarkBrowse:SetSeek(.T., aPesquisa)
    oMarkBrowse:SetUseFilter(.T.)

    oMarkBrowse:Activate()
    oTempTable:Delete()
    FwRestArea(aArea)
Return

Static Function xIniVars()
    Local nX    := 0
    Local nPos  := 0

    For nX := 1 to Len(aAuxil)
        If AllTrim(Upper(aAuxil[nX][1])) == AllTrim(Upper("Ok"))
            // aCampos  := {Nome do campo, tipo, tamanho, decimal}
            // aColunas := {Descrição do campo, nome do campo, tipo, tamanho, decimal, picture}    
            aadd(aCampos,   {;
                                aAuxil[nX][1],;
                                "C"          ,;
                                2            ,;
                                0             ;
                            }) 

            aadd(aColunas,  {;
                                aAuxil[nX][1],;
                                aAuxil[nX][1],;
                                "C"          ,;
                                2            ,;
                                0            ,;
                                "@!"          ;
                            }) 
        Else
            aadd(aCampos,   {;
                                aAuxil[nX][1]           ,;
                                TamSx3(aAuxil[nX][2])[3],;
                                TamSx3(aAuxil[nX][2])[1],;
                                TamSx3(aAuxil[nX][2])[2];
                            }) 
            aadd(aColunas,  {;
                                aAuxil[nX][1],;
                                aAuxil[nX][1],;
                                TamSx3(aAuxil[nX][2])[3],;
                                TamSx3(aAuxil[nX][2])[1],;
                                TamSx3(aAuxil[nX][2])[2],;
                                iif(Upper(AllTrim(aAuxil[nX][1])) == "FILIAL", "@!",X3Picture(aAuxil[nX][2]));
                            }) 
        EndIf
    Next nX

    // Tratativa para remover a coluna "OK"
    // No temporary browser ela já aparece quando se usa SetFieldMark. 
    nPos := aScan(aColunas, {|x| Upper(AllTrim(x[1])) == AllTrim("OK")})
    aFields := aClone(aColunas)
    aDel(aFields, nPos)
    aSize(aFields, len(aColunas) - 1)

    // Estrutura aColunas (oMarkBrowse:SetFields) dá tabela temporaria.
    // [n][01] Descrição do campo
    // [n][02] Nome do campo
    // [n][03] Tipo
    // [n][04] Tamanho
    // [n][05] Decimal
    // [n][06] Picture
Return

Static Function xFeedTmp() 
    Local aArea     := FwGetArea()
    Local aSb1      := SB1->(FwGetArea())
    Local aSb2      := SB2->(FwGetArea())

    DbSelectArea("SB2")
    SB2->(DbGoTop())
    SB2->(DbSetOrder(1))

    If SB2->(MsSeek(FwXFilial("SB2")))
        While SB2->(!Eof()) .AND. SB2->B2_FILIAL == FwXFilial("SB2")
            If RecLock(cAlias, .T.)
                (cAlias)->Filial    := SB2->B2_FILIAL
                (cAlias)->Codigo    := SB2->B2_COD
                (cAlias)->Descricao := AllTrim(Posicione("SB1", 1, FwXFilial("SB1") + SB2->B2_COD, "B1_DESC"))
                (cAlias)->Lote      := Posicione("SB1", 1, FwXFilial("SB1") + SB2->B2_COD, "B1_RASTRO")
                (cAlias)->Endereco  := Posicione("SB1", 1, FwXFilial("SB1") + SB2->B2_COD, "B1_LOCALIZ")
                (cAlias)->Armazem   := SB2->B2_LOCAL
                (cAlias)->Saldo     := SB2->B2_QATU
                (cAlias)->CM        := SB2->B2_CM1
                (cAlias)->Valor     := SB2->B2_VATU1
                (cAlias)->(MsUnlock())
            EndIf
            SB2->(DbSkip())
        EndDo
    EndIf

    FwRestArea(aSb2)
    FwRestArea(aSb1)
    FwRestArea(aArea)
Return

Static Function MenuDef()
    Local aRotina := {}
    ADD OPTION aRotina TITLE 'Contagem' ACTION 'u_fCount' OPERATION 6 ACCESS 0
Return aRotina


Static Function ModelDef()
    Local oModel    := Nil
    Local oStTmp    := FwFormModelStruct():New()
    Local nX        := 0
    Local aNoCamp   := {}

    aEval(aAuxil, {|x| aadd(aNoCamp, AllTrim(x[1]))})

    oStTmp:AddTable(cAlias, aNoCamp, "Temporaria")

    For nX := 1 to Len(aNoCamp)        
        oStTmp:AddField(;
            aCampos[nX][1],;                                                                                     // [01]  C   Titulo do campo
            aCampos[nX][1],;                                                                                     // [02]  C   ToolTip do campo
            aCampos[nX][1],;                                                                                     // [03]  C   Id do Field
            aCampos[nX][2],;                                                                                     // [04]  C   Tipo do campo
            aCampos[nX][3],;                                                                                     // [05]  N   Tamanho do campo
            aCampos[nX][4],;                                                                                     // [06]  N   Decimal do campo
            Nil,;                                                                                                // [07]  B   Code-block de validaÃ§Ã£o do campo
            Nil,;                                                                                                // [08]  B   Code-block de validaÃ§Ã£o When do campo
            {},;                                                                                                 // [09]  A   Lista de valores permitido do campo
            iif(nX >= 3, .T., .F.),;                                                                             // [10]  L   Indica se o campo tem preenchimento obrigatÃ³rio
            FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI," + cAlias + "->" + aCampos[nX][1] + ",'')"),;    // [11]  B   Code-block de inicializacao do campo
            .T.,;                                                                                                // [12]  L   Indica se trata-se de um campo chave
            .F.,;                                                                                                // [13]  L   Indica se o campo pode receber valor em uma operaÃ§Ã£o de update.
            .F.)                                                                                                 // [14]  L   Indica se o campo Ã© virtual   
    Next nX

    oModel := MpFormModel():New("diagnesM", /*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/ )
    oModel:AddFields("FormDiag", /* cOwnser */, oStTmp)
    oModel:SetPrimaryKey({"Filial", "Codigo"})
    oModel:SetDescription("Diagnest - 2024")
    oModel:GetModel("FormDiag"):SetDescription("Formulário Diagnest - 2024")
Return oModel

Static Function ViewDef()
    Local oModel := FwLoadModel("diagnest")
    Local oStTmp := FwFormViewStruct():New()
    Local oView  := Nil
    Local nX     := 0

    For nX := 1 to Len(aColunas)
        oStTmp:AddField(;
            aColunas[nX][1],;               // [01]  C   Nome do Campo
            StrZero(nX, 2),;                // [02]  C   Ordem
            aColunas[nX][1],;               // [03]  C   Titulo do campo
            aColunas[nX][2],;               // [04]  C   Descricao do campo
            Nil,;                           // [05]  A   Array com Help
            aColunas[nX][3],;               // [06]  C   Tipo do campo
            aColunas[nX][6],;               // [07]  C   Picture
            Nil,;                           // [08]  B   Bloco de PictTre Var
            Nil,;                           // [09]  C   Consulta F3
            Iif(INCLUI, .T., .F.),;         // [10]  L   Indica se o campo Ã© alteravel
            Nil,;                           // [11]  C   Pasta do campo
            Nil,;                           // [12]  C   Agrupamento do campo
            Nil,;                           // [13]  A   Lista de valores permitido do campo (Combo)
            Nil,;                           // [14]  N   Tamanho maximo da maior opÃ§Ã£o do combo
            Nil,;                           // [15]  C   Inicializador de Browse
            Nil,;                           // [16]  L   Indica se o campo Ã© virtual
            Nil,;                           // [17]  C   Picture Variavel
            Nil)                            // [18]  L   Indica pulo de linha apÃ³s o campo
    Next nX

    // Trataivas feitas para não questionar campos obrigátior na inclusão.
    // Avaliar isso pois a ideia não é ter inclusão nesse projeto, nem alteração e nem exclusão.
    oStTmp:RemoveField(aColunas[1][1]) // Ok
    oStTmp:RemoveField(aColunas[2][1]) // Filial

    oView := FwFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_TMP", oStTmp, "FormDiag")
    oView:CreateHorizontalBox("TELA", 100)
    oView:SetCloseOnOk({|| .T.})
    oView:SetOwnerView("VIEW_TMP", "TELA")
Return oView

User Function fCount()
    Local aArea := (cAlias)->(FwGetArea())
    Local cMark := oMarkBrowse:Mark()
    Local nQtd  := 0

    (cAlias)->(DbGoTop())

    While (cAlias)->(!Eof())
        If oMarkBrowse:isMark(cMark)
            nQtd++
        EndIf
    
        (cAlias)->(DbSkip())
    EndDo

    MsgAlert(cValToChar(nQtd) + " itens selecionados.","Informação.")
    FwRestArea(aArea)
Return
