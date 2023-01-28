#include 'totvs.ch'

/*/{Protheus.doc} YT0001
    Grava dados de cotacao diaria na tabela SM2. Essa funcao sera acionada automaticamente a partir do ponto de entrada ...
    @type  User Function 
    @author Klaus Wolfgram
    @since 21/01/2023
    @version 1.0

    @history 21/01/2023, Klaus Wolfgram, Inclusao do arquivo de codigo fonte.    
    /*/
User Function YT0001()

    Local cURL      := 'https://www4.bcb.gov.br/download/fechamento/' //20220119.csv
    Local cData     := dtos(datavalida(ddatabase -1,.F.))
    Local cArquivo  := ''
    Local cDirMoeda := '\_bcb\'
    Local cBuffer   := ''
    Local aLinha    := array(0)
    Local nHdl      := 0
    Local nUSDComp  := 0
    Local nUSDVend  := 0
    Local nEURComp  := 0
    Local nEURVend  := 0

    cURL            += cData + '.csv'

    cArquivo        := httpget(cURL) 

    IF .not. existDir(cDirMoeda)
        makeDir(cDirMoeda)
    EndIF  

    memowrite(cDirMoeda + cData + '.csv',cArquivo)

    nHdl            := FT_FUSE(cDirMoeda + cData + '.csv')

    IF nHdl = -1
        fwAlertError('ERRO NA ABERTURA DO ARQUIVO DE COTACOES','[ERRO]')
        return
    EndIF

    FT_FGOTOP()

    While .not. FT_FEOF()   

        cBuffer := FT_FREADLN()
        aLinha  := strtokarr(cBuffer,";")

        IF valtype(aLinha) <> 'A'
            FT_FSKIP()
            Loop
        EndIF

        IF len(aLinha) < 6
            FT_FSKIP()
            Loop
        EndIF

        IF alltrim(aLinha[4]) == 'USD'
            
            nUSDComp := val(strtran(aLinha[5],",","."))
            nUSDVend := val(strtran(aLinha[6],",","."))

            FT_FSKIP()
            Loop

        EndIF  

        IF alltrim(aLinha[4]) == 'EUR'
            
            nEURComp := val(strtran(aLinha[5],",","."))
            nEURVend := val(strtran(aLinha[6],",","."))

            FT_FSKIP()
            Loop
            
        EndIF           

        FT_FSKIP()

    Enddo 

    FT_FUSE()

    IF SM2->(dbSetOrder(1),dbSeek(ddatabase))       
        IF SM2->M2_INFORM == 'S' .and. SM2->M2_MOEDA2 == nUSDComp .and. SM2->M2_MOEDA3 == nUSDVend
             return
        Else           
            SM2->(reclock(alias(),.F.)  ,; 
                M2_DATA   := ddatabase  ,; 
                M2_INFORM := 'S'        ,; 
                M2_MOEDA2 := nUSDComp   ,; 
                M2_MOEDA3 := nUSDVend   ,; 
                M2_MOEDA4 := nEURComp   ,; 
                M2_MOEDA5 := nEURVend   ,;
                msunlock())    
        EndIF
    Else
        SM2->(reclock(alias(),.T.)  ,; 
            M2_DATA   := ddatabase  ,; 
            M2_INFORM := 'S'        ,; 
            M2_MOEDA2 := nUSDComp   ,; 
            M2_MOEDA3 := nUSDVend   ,; 
            M2_MOEDA4 := nEURComp   ,; 
            M2_MOEDA5 := nEURVend   ,;
            msunlock())    
    EndIF    
    
Return 
