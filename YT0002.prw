#include 'totvs.ch'

/*/{Protheus.doc} YT0002
    Programa para consulta de dados cadastrais de empresas a partir de CNPJ enviado via parametro ou por retorno da funcao readvar()
    @type  User Function 
    @author Klaus Wolfgram
    @since 24/01/2023
    @version 1.0
    @param cCNPJ, C, CNPJ a ser pesquisado
    @return xRet, undefined, Se o parametro cCNPJ for informado, significa que a funcao esta sendo acionada a partir de gatilho.
                             Nesse caso retorna um array com os dados cadastrais e atualiza a variavel publica __aRecWS com os mesmos dados retornados.
                             Caso o parametro seja nulo e a funcao readvar() retorne um campo de CGC do cadastro de clientes ou fornecedores,
                             a funcao identifica se esta sendo acionado a partir do cadastro de clientes ou fornecedores, atualiza os campos de endereco do cadastro
                             e retorna .T., pois significa que o acionamento foi feito a partir da validacao de usuario do campo XX_CGC.
    @see https://developers.receitaws.com.br/#/operations/queryCNPJFree
    @see https://tdn.totvs.com/display/tec/HTTPGet
    @see https://tdn.totvs.com/display/tec/Classe+JsonObject
    @see https://tdn.totvs.com/display/tec/Type
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=24347162 (Funcao valtype())
    @see https://tdn.totvs.com/pages/viewpage.action?pageId=6063097 (Escopo de variaveis)
    /*/
User Function YT0002(cParam)

    Local cCNPJ    := ''
    Local cURL     := 'https://www.receitaws.com.br/v1/cnpj/'
    Local cReadVar := readvar()
    Local oJsonRet := nil
    Local xJsonRet := nil
    Local xRet     := nil

    Default cParam := ''

    IF empty(cParam)

        IF empty(cReadVar)
            return xRet
        EndIF

        IF .not. alltrim(cReadvar) $ "M->A1_CGC|M->A2_CGC"
            xRet   := .T.
            return xRet
        EndIF

        cCNPJ       := &(cReadVar)   
        xRet        := .T.

    Else

        cCNPJ       := cParam  
        xRet        := array(0)    

    EndIF

    cCNPJ           := strtran(strtran(strtran(cCNPJ,".",""),"-",""),"/","")
    cURL            += cCNPJ

    cTxtRet         := httpGet(cURL)
    oJsonRet        := jsonObject():new()
    xJsonRet        := oJsonRet:fromJson(fwNoAccent(cTxtRet))   

    IF valtype(xJsonRet) <> 'U' 
        return xRet
    EndIF     

    cNome        := oJsonRet:getJsonText('nome'               )
    cNome        := fwNoAccent(upper(iif(cNome    == 'null','',cNome   )))
    
    cNomeRe      := oJsonRet:getJsonText('fantasia'           )
    cNomeRe      := fwNoAccent(upper(iif(cNomeRe  == 'null','',cNomeRe )))
    
    cDtAber      := oJsonRet:getJsonText('abertura'           )
    cDtAber      := fwNoAccent(upper(iif(cDtAber  == 'null','',cDtAber )))
    
    cBairro      := oJsonRet:getJsonText('bairro'             )
    cBairro      := fwNoAccent(upper(iif(cBairro  == 'null','',cBairro )))
    
    cCep         := oJsonRet:getJsonText('cep'                )
    cCep         := fwNoAccent(upper(iif(cCep     == 'null','',cCep    )))
    
    cEnd         := oJsonRet:getJsonText('logradouro'         )
    cEnd         := fwNoAccent(upper(iif(cEnd     == 'null','',cEnd    )))
    
    cNrEnd       := oJsonRet:getJsonText('numero'             )
    cNrEnd       := fwNoAccent(upper(iif(cNrEnd   == 'null','',cNrEnd  )))
    
    cCidade      := oJsonRet:getJsonText('municipio'          )
    cCidade      := fwNoAccent(upper(iif(cCidade  == 'null','',cCidade )))
    
    cEstado      := oJsonRet:getJsonText('uf'                 )
    cEstado      := fwNoAccent(upper(iif(cEstado  == 'null','',cEstado )))
    
    cCompl       := oJsonRet:getJsonText('complemento'        )
    cCompl       := fwNoAccent(upper(iif(cCompl   == 'null','',cCompl  )))
    
    cTel         := oJsonRet:getJsonText('telefone'           )
    cTel         := fwNoAccent(upper(iif(cTel     == 'null','',cTel    )))
    
    cEmail       := oJsonRet:getJsonText('email'              )
    cEmail       := fwNoAccent(upper(iif(cEmail   == 'null','',cEmail  )))
    
    cSitua       := oJsonRet:getJsonText('situacao'           )
    cSitua       := fwNoAccent(upper(iif(cSitua   == 'null','',cSitua  )))
    
    cDtSitu      := oJsonRet:getJsonText('data_situacao'      )
    cDtSitu      := fwNoAccent(upper(iif(cDtSitu  == 'null','',cDtSitu )))    

    IF .not. empty(cNrEnd)
        cEnd := alltrim(cEnd) + ', ' + cNrEnd
    EndIF    

    cCodMun      := ''

    IF .not. empty(cCidade) .and. .not. empty(cEstado)
        cCodMun  := posicione('CC2',4,xFilial("CC2")+cEstado+cCidade,'CC2_CODMUN')
        cCodMun  := iif(valtype(cCodMun) == 'C',cCodMun,'')
    EndIF

    cCnae        := oJsonRet:getJsonObject('atividade_principal')

    IF valType(cCnae) == 'A'        
        cCnae       := cCnae[1]:getJsonText('code')       
        IF valtype(cCnae) == 'C'
            cCnae   := strtran(strtran(cCnae,"-",""),".","")
        Else
            cCnae   := '' 
        EndIF
    Else
        cCnae       := ''
    EndIF    

    aadd(xRet,cNome         )
    aadd(xRet,cNomeRe       )
    aadd(xRet,ctod(cDtAber) )
    aadd(xRet,cEstado       )
    aadd(xRet,cCodMun       )
    aadd(xRet,cCidade       )
    aadd(xRet,cBairro       )
    aadd(xRet,cEnd          )
    aadd(xRet,cCompl        )
    aadd(xRet,cCep          )
    aadd(xRet,cTel          )
    aadd(xRet,cEmail        )
    aadd(xRet,cSitua        )
    aadd(xRet,ctod(cDtSitu) )
    aadd(xRet,cCnae         )

    IF type('__aRecWS') <> 'A'
        Public __aRecWS     := aclone(xRet)
    Else    
        __aRecWS            := aclone(xRet)
    EndIF   

    IF "A1_CGC" $ cReadVar

        M->A1_NOME          := substr(cNome     ,1,tamSX3('A1_NOME'   )[1])
        M->A1_NREDUZ        := substr(cNomeRe   ,1,tamSX3('A1_NREDUZ' )[1])
        M->A1_END           := substr(cEnd      ,1,tamSX3('A1_END'    )[1])
        M->A1_BAIRRO        := substr(cBairro   ,1,tamSX3('A1_BAIRRO' )[1])
        M->A1_COD_MUN       := substr(cCodMun   ,1,tamSX3('A1_COD_MUN')[1])
        M->A1_MUN           := substr(cCidade   ,1,tamSX3('A1_MUN'    )[1])
        M->A1_EST           := substr(cEstado   ,1,tamSX3('A1_EST'    )[1])
        M->A1_COMPLEM       := substr(cCompl    ,1,tamSX3('A1_COMPLEM')[1])
        M->A1_CEP           := substr(cCep      ,1,tamSX3('A1_CEP'    )[1])
        M->A1_TEL           := substr(cTel      ,1,tamSX3('A1_TEL'    )[1])
        M->A1_EMAIL         := substr(cEmail    ,1,tamSX3('A1_EMAIL'  )[1])
        M->A1_CNAE          := substr(cCnae     ,1,tamSX3('A1_CNAE'   )[1])

        return .T.

    ElseIF "A2_CGC" $ cReadVar

        M->A2_NOME          := substr(cNome     ,1,tamSX3('A2_NOME'   )[1])
        M->A2_NREDUZ        := substr(cNomeRe   ,1,tamSX3('A2_NREDUZ' )[1])
        M->A2_END           := substr(cEnd      ,1,tamSX3('A2_END'    )[1])
        M->A2_BAIRRO        := substr(cBairro   ,1,tamSX3('A2_BAIRRO' )[1])
        M->A2_COD_MUN       := substr(cCodMun   ,1,tamSX3('A2_COD_MUN')[1])
        M->A2_MUN           := substr(cCidade   ,1,tamSX3('A2_MUN'    )[1])
        M->A2_EST           := substr(cEstado   ,1,tamSX3('A2_EST'    )[1])
        M->A2_COMPLEM       := substr(cCompl    ,1,tamSX3('A2_COMPLEM')[1])
        M->A2_CEP           := substr(cCep      ,1,tamSX3('A2_CEP'    )[1])
        M->A2_TEL           := substr(cTel      ,1,tamSX3('A2_TEL'    )[1])
        M->A2_EMAIL         := substr(cEmail    ,1,tamSX3('A2_EMAIL'  )[1])
        M->A2_CNAE          := substr(cCnae     ,1,tamSX3('A2_CNAE'   )[1])            

        return .T.

    EndIF

Return xRet
