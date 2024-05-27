#include 'totvs.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc}KAPP012
    Programa para geracao das medicoes de contratos de comodato. Pode ser acionado via menu do cadastro de medicoes ou a partir do schedule.
    @type  User Function 
    @author Klaus Wolfgram
    @since 10/02/2023
    /*/

User Function KAPP012(nPar)

    Local nOpc       := 0

    Default nPar     := 0

    IF isBlind()
        nOpc         := 0
    Else
        nOpc         := nPar    
    EndIF    

    //-- Acionado via schedule
    IF nOpc = 0    
        KAPP012()
    ElseIF nOpc = 1 //-- Acionado via menu
        fwMsgRun(,{|| KAPP012()},"Atualizando Medições","Aguarde...")
    ElseIF nOpc = 2 //-- Acionamento via ponto de entrada no modulo faturamento
        KAPP012() 
    ElseIF nOpc = 4 //-- Acionado via relatorio de medicoes    
        fwMsgRun(,{|| KAPP012()},"Atualizando Medições","Aguarde...")
    EndIF    
    
Return 

/*/{Protheus.doc} KAPP012
    Gera os registros de medicoes de contratos de comodato.
    @type  Static Function
    @author Klaus Wolfgram
    @since 10/02/2023
    /*/

Static Function KAPP012

    Local cAliasSQL := ''
    Local aRecCN9   := array(0)
    Local dDataPer  := date() //-- Data final do periodo de apuracao
    Local oModCND   := Nil
    Local lOk       := .T.
    Local lRPC      := .F.
    Local x

    //-- Caso a execucao esteja sendo feita sem ambiente preparado, inicia o ambiente
    IF type('cEmpAnt') <> 'C'
        rpcSetType(3)
        rpcSetEnv('01','0101')
        lRPC := .T.
    EndIF

    cAliasSQL       := getNextAlias()

    //-- Consulta SQL de contratos ativos
    BeginSQL alias cAliasSQL
        SELECT R_E_C_N_O_ RECCN9, CN9_FILIAL, CN9_NUMERO, CN9_DTINIC, CN9_DTASSI, CN9_YMETFA, CN9_YDTMED
        FROM %table:CN9% CN9
        WHERE CN9.%notdel%
        AND CN9_TPCTO = '001'
        AND CN9_SITUAC= '05'
        ORDER BY CN9_FILIAL, CN9_NUMERO
    EndSQL

    //-- Loop para verificar os contratos que esteja com periodo de apuracao encerrado
    While .not. (cAliasSQL)->(eof())

        //-- Posiciona no contrato
        CN9->(dbSetOrder(1),dbGoTo((cAliasSQL)->RECCN9))

        IF .not. aScan(aRecCN9,CN9->(recno())) = 0 //-- Ignora registro que ja esteja no array de controle
            (cAliasSQL)->(dbSkip())
            Loop
        EndIF    
        
        //-- Caso ja exista uma apuracao anterior, processa os registros a partir dessa data, caso contrario considera a data de inicio do contrato
        IF empty(CN9->CN9_YDTMED)
            dDataCN9 := CN9->(iif(empty(CN9_ASSINA),CN9_DTINIC,CN9_ASSINA))
        Else
            dDataCN9 := CN9->CN9_YDTMED    
        EndIF

        //-- Soma 1 mes a partir da dataCN9 para estabelecer o fim do periodo de apuracao
        dDataPer     := monthSum(dDataCN9,1)      

        //-- Caso a data fim do periodo seja superior a data corrente, significa que o periodo ainda esta aberto. Nesse caso o registro eh ignorado
        IF dDataPer > date()  
            (cAliasSQL)->(dbSkip())
            Loop 
        EndIF 

        //-- Adiciona o registro do contrato ao array de controle
        aadd(aRecCN9,CN9->(recno()))

        (cAliasSQL)->(dbSkip())
        
    Enddo

    (cAliasSQL)->(dbCloseArea())

    x := 1

    //-- Loop para processamento das medicoes
    While x <= Len(aRecCN9)

        //-- Posiciona no contrato e no registro do cliente do contrato
        CN9->(dbSetOrder(1),dbGoTo(aRecCN9[x]))
        CNC->(dbSetOrder(1),dbSeek(CN9->(CN9_FILIAL+CN9_NUMERO)))
        CNA->(dbSetOrder(1),dbSeek(CN9->(CN9_FILIAL+CN9_NUMERO)))

        //-- Atualiza o saldo da planilha do contrato
        IF CNA->CNA_SALDO <= 0
            CNA->(reclock(alias(),.F.), CNA_VLTOT := 999999999, CNA_SALDO := 999999999,msunlock())
        EndIF    

        //-- Recupera a data inicial do periodo de apuracao
        IF empty(CN9->CN9_YDTMED)
            dDataIni    := CN9->(iif(empty(CN9_ASSINA),CN9_DTINIC,CN9_ASSINA))
        Else
            dDataIni    := CN9->CN9_YDTMED
        EndIF        

        //-- Estabelece a data limite para o periodo de apuracao
        dDataPer        := monthSum(dDataIni,1)

        //-- Lista os titulos a serem considerados no periodo de apuracao 
        cAliasSQL       := getNextAlias()

        BeginSQL alias cAliasSQL
            SELECT (E1_VALOR - E1_DECRESC) E1_VALOR, E1_TIPO
            FROM %table:SE1% SE1
            WHERE SE1.%notdel%
            AND E1_CLIENTE =  %exp:CNC->CNC_CLIENT%
            AND E1_EMISSAO >= %exp:dDataIni% 
            AND E1_EMISSAO <  %exp:dDataPer%
            AND E1_TIPO IN ('NF','NCC')
        EndSQL

        //-- Soma o valor total dos titulos, descontando os registros de NCC
        nVlrNF          := 0

        While .not. (cAliasSQL)->(eof())
            
            IF (cAliasSQL)->E1_TIPO == 'NCC'
                nVlrNF -= (cAliasSQL)->E1_VALOR
            Else
                nVlrNF += (cAliasSQL)->E1_VALOR
            EndIF

            (cAliasSQL)->(dbSkip())

        Enddo

        (cAliasSQL)->(dbCloseArea())

        //-- Atualiza variavel de controle sobre a gravacao da medicao
        lOk := .T.

        //-- Caso o valor seja positivo, executa a rotina automatica de inclusao de medicao
        IF nVlrNF > 0

            //-- Carrega o modelo de dados para execucao da rotina automatica via MVC
            oModCND := fwLoadModel('CNTA121')
            oModCND:setOperation(MODEL_OPERATION_INSERT)

            //-- Verifica se o modelo de dados pode ser ativado
            lCanActiv := oModCND:canActivate()

            IF lCanActiv

                //-- Posiciona no primeiro registro de equipamento em comodato
                IF SZ1->(dbSetOrder(1),dbSeek(CN9->(CN9_FILIAL+CN9_NUMERO)))
                
                    IF .not. SB1->(dbSetOrder(1),dbSeek(xFilial(alias())+SZ1->Z1_PRODUTO))

                        SB1->(dbSetOrder(1),dbSeek(xFilial(alias())+"AI0000"))

                    EndIF    
                
                Else

                    SB1->(dbSetOrder(1),dbSeek(xFilial(alias())+"AI0000"))

                EndIF

                cObs := "PERIODO DE MEDICAO: " + dtoc(dDataIni) + " A " + dtoc(dDataPer - 1)
                cObs += CRLF + "VALOR APURADO: " + transform(nVlrNF,"@E 999,999,999.99")
                
                ddatabase := dDataPer

                //-- Ativa o modelo de dados
                oModCND:activate()

                //-- Preenche os dados da medicao
                oModCND:setValue('CNDMASTER','CND_CONTRA',CN9->CN9_NUMERO                               )
                oModCND:setValue('CNDMASTER','CND_COMPET',substr(dtoc(dDataIni),4)                      )
                oModCND:setValue('CNDMASTER','CND_DTINIC',dDataIni                                      )
                oModCND:setValue('CNDMASTER','CND_DTFIM' ,dDataPer - 1                                  )
                oModCND:setValue('CNDMASTER','CND_RCCOMP','1'                                           )
                oModCND:setValue('CNDMASTER','CND_OBS'   ,cObs                                          )
                oModCND:setValue('CXNDETAIL','CXN_CHECK' ,.T.                                           )
                oModCND:getModel('CNEDETAIL'):loadValue('CNE_ITEM',padl("1",tamSX3('CNE_ITEM')[1],'0')  )
                oModCND:setValue('CNEDETAIL','CNE_PRODUT',SB1->B1_COD                                   )
                oModCND:setValue('CNEDETAIL','CNE_QUANT' ,1                                             )
                oModCND:setValue('CNEDETAIL','CNE_VLUNIT',nVlrNF                                        )
                oModCND:setValue('CNEDETAIL','CNE_PEDTIT','2'                                           )

                //-- Valida os dados preenchidos
                lOk := oModCND:vldData()

                IF lOk

                    //-- Executa a gravacao da medicao
                    oModCND:commitData()

                    aErrorMsg := array(0)

                    //-- Verifica ocorrencia de erros
                    IF oModCND:hasErrorMessage()
                        aErrorMsg := oModCND:getErrorMessage()
                        lOk := .F.
                    Else
                        CND->(reclock(alias(),.F.), CND_SITUAC := 'E', msunlock())    
                    EndIF

                    //-- Tratamento de erro
                    cErrorMsg := ''

                    IF valType(aErrorMsg) == 'A'
                        aEval(aErrorMsg,{|cError| cErrorMsg += CRLF + iif(valType(cError) == 'C',cError,"")})
                    ElseIF valType(aErrorMsg) == 'C'
                        cErrorMsg := aErrorMsg    
                    EndIF

                    IF .not. lRPC .and. .not. empty(cErrorMsg)
                        fwAlertError("ERRO NA MEDICAO DO CONTRATO: " + CN9->CN9_NUMERO + CRLF + cErrorMsg,'ERRO')
                    EndIF        

                    //-- Desativa o modelo de dados
                    oModCND:deActivate()

                //-- Tratamento de erro na validacao dos dados do modelo
                Else

                    aErrorMsg := oModCND:getErrorMessage()

                    cErrorMsg := ''

                    IF valType(aErrorMsg) == 'A'
                        aEval(aErrorMsg,{|cError| cErrorMsg += CRLF + iif(valType(cError) == 'C',cError,"")})
                    ElseIF valType(aErrorMsg) == 'C'
                        cErrorMsg := aErrorMsg    
                    EndIF

                    IF .not. lRPC .and. .not. empty(cErrorMsg)
                        fwAlertError("ERRO NA MEDICAO DO CONTRATO: " + CN9->CN9_NUMERO + cErrorMsg,'ERRO')
                    EndIF        

                    //-- Desativa o modelo de dados
                    oModCND:deActivate()                     

                EndIF

            //-- Tratamento de erro na ativacao do modelo
            Else

                aErrorMsg := oModCND:getErrorMessage()

                cErrorMsg := ''

                IF valType(aErrorMsg) == 'A'
                    aEval(aErrorMsg,{|cError| cErrorMsg += CRLF + iif(valType(cError) == 'C',cError,"")})
                ElseIF valType(aErrorMsg) == 'C'
                    cErrorMsg := aErrorMsg    
                EndIF

                IF .not. lRPC .and. .not. empty(cErrorMsg)
                    fwAlertError("ERRO NA MEDICAO DO CONTRATO: " + CN9->CN9_NUMERO + CRLF + cErrorMsg,'ERRO')
                EndIF                              

            EndIF   

        EndIF 

        //-- Caso a gravacao tenha ocorrido com sucesso, grava as informacoes do periodo de medicao
        IF lOk

            CN9->(reclock(alias(),.F.), CN9_YDTMED := dDataPer, CN9_YVLMED := nVlrNF,msunlock())

            //-- Verifica se ha mais medicoes a serem geradas, se houver, reinicia o loop de execucao
            IF monthSum(CN9->CN9_YDTMED,1) < date()
                Loop
            EndIF

        EndIF  

        //-- Incrementa variavel de controle do loop
        x++ 

    Enddo

    //-- Libera o ambiente caso tenha sido preparado por rpcSetEnv()
    IF lRPC
        rpcClearEnv()
    EndIF    
    
Return

/*/{Protheus.doc} KAPP012N
    Funcao para geracao do numero do contrato. Acionado no inicializador do campo CN9_NUMERO
    @type  User Function 
    @author Klaus Wolfgram
    @since 10/02/2023
    @version 1.0
    /*/
User Function KAPP012N

    Local cNumero   := getSxeNum('CN9','CN9_NUMERO')
    cNumero         := strzero(val(cNumero),6)
    
Return cNumero

/*/{Protheus.doc} KAPP012A
    Funcao auxiliar para gravacao dos itens de comodato.
    @type  User Function 
    @author Klaus Wolfgram
    @since 08/02/2023
    /*/
User Function KAPP012A

    Local oDlg
    Local oGet
    Local cTitulo   := 'ITEMS DE COMODATO'
    Local nOpca     := 0
    Local nStyle    := GD_INSERT+GD_DELETE+GD_UPDATE
    Local x,y

    Private aHeader := array(0)
    Private aCols   := array(0)

    &("SX3->(dbSetOrder(1),dbSeek('SZ1'))")

    While .not. &("SX3->(eof())") .and. &("SX3->X3_ARQUIVO") == 'SZ1'

        aTam 		:= tamSX3(&("SX3->X3_CAMPO"))
        
        IF x3uso(&("SX3->X3_USADO")) .and. .not. alltrim(&("SX3->X3_CAMPO")) $ 'Z1_FILIAL|Z1_CONTRAT'
            aadd(aHeader,{AllTrim(&("SX3->X3_TITULO")),&("SX3->X3_CAMPO"),pesqpict("SZ1",&("SX3->X3_CAMPO"),aTam[1]),aTam[1],aTam[2],'',.T.,&("SX3->X3_TIPO"),'',''})
        EndIF        


        &("SX3->(dbSkip())")

    Enddo

    IF .not. SZ1->(dbSetOrder(1),dbSeek(CN9->(CN9_FILIAL+CN9_NUMERO)))

        aCols := array(1,Len(aHeader) + 1)

        For x := 1 To Len(aHeader)

            Do Case
                Case aHeader[x,8] == 'C'
                    aCols[1,x] := space(aHeader[x,4])
                Case aHeader[x,8] == 'N'
                    aCols[1,x] := 0
                Case aHeader[x,8] == 'D'
                    aCols[1,x] := STOD('')
                Case aHeader[x,8] == 'L'
                    aCols[1,x] := .F.
                OtherWise 
                    aCols[1,x] := ''                
            End Case

            IF alltrim(aHeader[x,2]) == 'Z1_SEQ'
                aCols[1,x]  := '001'
            EndIF

            IF alltrim(aHeader[x,2]) == 'Z1_STATUS'
                aCols[1,x]  := 'A'
            EndIF            

        Next

    Else

        While .not. SZ1->(eof()) .and. SZ1->(Z1_FILIAL+Z1_CONTRAT) == CN9->(CN9_FILIAL+CN9_NUMERO)

            aLinha := {}

            For x := 1 To Len(aHeader)
                aadd(aLinha,SZ1->&(aHeader[x,2]))
            Next

            aadd(aLinha,.F.)
            aadd(aCols,aLinha)            

            SZ1->(dbSkip())

        Enddo

    EndIF

    oDlg            := tDialog():new(0,0,370,1050,cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    oGet            := msNewGetDados():new(010,010,160,520,nStyle,"allwaystrue()","allwaystrue()","+Z1_SEQ",Nil,0,9999,"allwaystrue()",Nil,"U_KAPP012D()",oDlg,aHeader,aCols,,)  

    oBtn            := tButton():new(170,400,"Cancelar"	,oDlg,{||nOpca := 0, oDlg:end()	},50,12,,,,.T.,,'Cancelar'	)
	oBtn            := tButton():new(170,470,"Confirmar",oDlg,{||nOpca := 1, oDlg:end()	},50,12,,,,.T.,,'Confirmar' )    

	//-- ativa a interface grafica
	oDlg:activate(,,,.T.,,)  

    IF nOpca = 0
        Return
    EndIF   

    aCols   := oGet:aCols
    aHeader := oGet:aHeader

    For x   := 1 To Len(aCols)   

        lInc := .T. 

        IF gddeleted(x,aHeader,aCols)

            cChaveSZ1   := CN9->(CN9_FILIAL+CN9_NUMERO)+gdfieldget('Z1_SEQ',x)
            
            IF SZ1->(dbSetOrder(1),dbSeek(cChaveSZ1))
                SZ1->(reclock(alias(),.F.),dbdelete(),msunlock())
            EndIF

            Loop

        EndIF

        cChaveSZ1   := CN9->(CN9_FILIAL+CN9_NUMERO)+gdfieldget('Z1_SEQ',x)

        IF SZ1->(dbSetOrder(1),dbSeek(cChaveSZ1))
            lInc    := .F.
        EndIF

        SZ1->(reclock(alias(),lInc))
            
            SZ1->Z1_FILIAL := CN9->CN9_FILIAL
            SZ1->Z1_CONTRAT:= CN9->CN9_NUMERO

            For y := 1 To Len(aHeader)
                
                SX3->(dbSetOrder(2),dbSeek(aHeader[y,2]))    

                IF SX3->X3_CONTEXT == 'V'
                    Loop
                EndIF   

                cCampo := aHeader[y,2]
                xCont  := aCols[x,y]

                SZ1->&(cCampo) := xCont

            Next

            IF CTD->(dbSetOrder(1),dbSeek(xFilial(alias())+'P'+SZ1->Z1_PATRIMO))

                SZ1->Z1_ITEMCTA     := CTD->CTD_ITEM

            Else

                IF .not. CTH->(dbSetOrder(1),dbSeek(xFilial(alias()) + 'B1' + alltrim(SZ1->Z1_PRODUTO)))
                    
                    CTH->(reclock(alias(),.T.))
                        CTH->CTH_FILIAL := CTH->(xFilial(alias()))
                        CTH->CTH_CLVL   := 'B1' + alltrim(SZ1->Z1_PRODUTO)
                        CTH->CTH_CLASSE := '2'
                        CTH->CTH_NORMAL := '0'
                        CTH->CTH_DESC01 := SZ1->Z1_DESC
                    CTH->(msunlock())

                EndIF

                CTD->(reclock(alias(),.T.))
                    CTD->CTD_FILIAL     := CTD->(xFilial(alias()))
                    CTD->CTD_ITEM       := 'P' + SZ1->Z1_PATRIMO
                    CTD->CTD_CLASSE     := '2'
                    CTD->CTD_NORMAL     := '0'
                    CTD->CTD_DESC01     := '[PATRIMONIO]' + alltrim(SZ1->Z1_PRODUTO) + '/' + substr(SZ1->Z1_DESC,1,20) 
                CTD->(msunlock())

                SZ1->Z1_ITEMCTA     := CTD->CTD_ITEM

            EndIF

        SZ1->(msunlock())

    Next   
    
Return 

/*/{Protheus.doc} KAPP012B
    Funcao auxiliar para geracao dos pedidos de remessa de comodato de contratos vigentes.
    @type  User Function 
    @author Klaus Wolfgram
    @since 10/02/2023
    /*/
User Function KAPP012B(cAlias,nRecno,nOpc)

    //-- Executa a geracao dos pedidos de remessa de comodato.
    IF fwAlertYesNo("Confirma a geração dos pedidos de remessa?","NF de Remessa")
        fwMsgRun(,{|| U_KAPP012C()},"Processando pedidos de remessa.","Aguarde...")
    EndIF    
    
Return 

/*/{Protheus.doc} KAPP012C
    Funcao auxiliar para geracao dos pedidos de remessa de comodato.
    @type  User Function 
    @author Klaus Wolfgram
    @since 10/02/2023
    /*/
User Function KAPP012C()

    Local cAliasSQL     := getNextAlias()
    Local aRecSZ1       := array(0)
    Local aCab          := array(0)
    Local aItem         := array(0)
    Local aItens        := array(0)
    Local x

    Private lMsErroAuto := .f.

    BeginSQL alias cAliasSQL
        SELECT R_E_C_N_O_ RECSZ1 FROM %table:SZ1% SZ1
        WHERE SZ1.%notdel%
        AND Z1_FILIAL = %exp:CN9->CN9_FILIAL%
        AND Z1_CONTRAT = %exp:CN9->CN9_NUMERO%
        AND Z1_PRODUTO <> ' '
        AND Z1_PEDIDO  = ' '
        AND Z1_GERPED  <> 'N'
        AND (Z1_OPERAC <> ' ' OR Z1_TES <> ' ' )
        ORDER BY Z1_SEQ
    EndSQL

    (cAliasSQL)->(dbEval({|| aadd(aRecSZ1,RECSZ1)}),dbCloseArea())

    IF Len(aRecSZ1) = 0

        //-- Abre a tela para proceder com a emissao da nota fiscal
        mata410()    
        return 

    EndIF    

    For x := 1 To Len(aRecSZ1)

        SZ1->(dbSetOrder(1),dbGoTo(aRecSZ1[x]))
        SB1->(dbSetOrder(1),dbSeek(xFilial(alias())+SZ1->Z1_PRODUTO)) 

        nPrc := iif(SB1->B1_PRV1 = 0,100,SB1->B1_PRV1)

        aItem := array(0)
        aadd(aItem,{"C6_ITEM"   ,strzero(x,2)                   ,Nil})
        aadd(aItem,{"C6_PRODUTO",SB1->B1_COD                    ,Nil})
        aadd(aItem,{"C6_QTDVEN" ,1                              ,Nil})
        aadd(aItem,{"C6_PRCVEN" ,nPrc                           ,Nil})
        aadd(aItem,{"C6_PRUNIT" ,nPrc                           ,Nil})

        IF empty(SZ1->Z1_TES) .and. empty(SZ1->Z1_OPERAC)
            aadd(aItem,{"C6_OPER",'B'                           ,Nil})
        Else        
        
            IF .not. empty(SZ1->Z1_OPERAC)
                aadd(aItem,{"C6_OPER",SZ1->Z1_OPERAC            ,Nil})
            EndIF

            IF .not. empty(SZ1->Z1_TES)    
                aadd(aItem,{"C6_TES" ,SZ1->Z1_TES               ,Nil})
            EndIF  

        EndIF  

        aadd(aItem,{"C6_LOCAL"  ,SB1->B1_LOCPAD                 ,Nil})
        aadd(aItem,{"C6_ITEMCTA",SZ1->Z1_ITEMCTA                ,Nil})

        aadd(aItens,aItem)

    Next

    CNA->(dbSetOrder(1),dbSeek(CN9->(CN9_FILIAL+CN9_NUMERO)))
    SA1->(dbSetOrder(1),dbSeek(xFilial(alias())+CNA->(CNA_CLIENT+CNA_LOJACL)))

    aadd(aCab,{"C5_TIPO"    ,'N'            ,Nil})
    aadd(aCab,{"C5_CLIENTE" ,SA1->A1_COD    ,Nil})
    aadd(aCab,{"C5_LOJACLI" ,SA1->A1_LOJA   ,Nil})
    aadd(aCab,{"C5_CONDPAG" ,'001'          ,Nil})    

    msExecAuto({|x,y| mata410(x,y,3)},aCab,aItens)

    IF lMsErroAuto
        mostraerro()
        return
    EndIF

    For x := 1 To Len(aRecSZ1)
        SZ1->(dbSetOrder(1),dbGoTo(aRecSZ1[x]),reclock(alias(),.F.), Z1_PEDIDO := SC5->C5_NUM, Z1_STATUS := 'P', msunlock())
    Next    

    //-- Abre a tela para proceder com a emissao da nota fiscal
    mata410()

Return 

/*/{Protheus.doc} KAPP012D
    Valida a delecao de uma linha
    @type  User Function 
    @author Klaus Wolfgram
    @since 09/02/2023
    @version 1.0
    /*/
User Function KAPP012D()

    IF empty(gdFieldGet('Z1_PEDIDO'))
        return .T.
    EndIF  

    IF .not. SC5->(dbSetOrder(1),dbSeek(CN9->CN9_FILIAL+gdFieldGet('Z1_PEDIDO')))
        return .T.
    EndIF

    fwAlertError('Nao eh possivel excluir um item que possua pedido para emissao de nota de comodato.','[ERRO]')    
    
Return .F.

/*/{Protheus.doc} KAPP012F
    Valida a alteracao de campo
    @type  User Function 
    @author Klaus Wolfgram
    @since 09/02/2023
    /*/
User Function KAPP012F()

    IF empty(gdFieldGet('Z1_PEDIDO'))
        return .T.
    EndIF  

    IF .not. SC5->(dbSetOrder(1),dbSeek(CN9->CN9_FILIAL+gdFieldGet('Z1_PEDIDO')))
        return .T.
    EndIF

    fwAlertError('Nao eh possivel editar um item que possua pedido para emissao de nota de comodato.','[ERRO]')

Return .F.

/*/{Protheus.doc} KAPP012G
    Funcao para uso na validacao do campo CN9_YCLIEN. 
    Preenche campos adicionais.
    @type  User Function 
    @author Klaus Wolfgram
    @since 03/03/2023
    @version 1.0
    /*/

User Function KAPP012G

    Local cReadVar := readvar()
    Local cConteud := &(cReadvar)
    Local cChave   := ''

    IF cReadVar == 'M->CN9_YCLIEN'
        cChave     := cConteud
    ElseIF cReadVar == 'M->CN9_YLOJAC'   
        cChave     := M->(CN9_YCLIEN+CN9_YLOJAC)
    EndIF 

    IF .not. SA1->(dbSetOrder(1),dbSeek(xFilial(alias())+cChave))
        fwAlertError('Cliente nao encontrado','[ERRO]')
        return .F.
    EndIF

    //-- Atualiza dados do cabecalho
    M->CN9_YNOME    := substr(SA1->A1_NOME  ,1,29)    
    M->CN9_YNREDU   := substr(SA1->A1_NREDUZ,1,29)

    //-- Atualiza cliente do contrato
    fwFldPut('CNC_CLIENT',SA1->A1_COD   )
    fwFldPut('CNC_LOJACL',SA1->A1_LOJA  )

    //-- Atualiza cliente da planilha do contrato
    fwFldPut('CNA_CLIENT',SA1->A1_COD   )
    fwFldPut('CNA_LOJACL',SA1->A1_LOJA  )     

Return .T.


/*/{Protheus.doc} KAPP012H
    Funcao auxiliar para gerar medicoes
    @type  User Function 
    @author Klaus Wolfgram
    @since 29/04/2023
    /*/
User Function KAPP012H

    Private dDataAux := stod('20230101')
    
    TCSQLExec("UPDATE " + retSqlName("CN9") + " SET CN9_YDTMED = ' ' WHERE D_E_L_E_T_ = ' ' ")
    TCSQLExec("UPDATE " + retSqlName("CND") + " SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ WHERE D_E_L_E_T_ = ' ' ")

    While dDataAux < date()

        IF substr(dtos(dDataAux),7,2) == '16'
            lAux := .T.
        EndIF    

        U_KAPP012(4)
        
        dDataAux := dDataAux + 1

    Enddo

    fwAlertInfo('Fim do processamento')
    
Return 
