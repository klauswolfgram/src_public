#include 'totvs.ch'

class cliente from pessoa

    method new() constructor
    method grava_cliente()

endclass

method new( p_nome     ,p_nm_red  ,p_cpf_cnpj  ,p_cep      ,p_endereco ,p_compl  ,;
            p_bairro   ,p_cidade  ,p_cod_ibge  ,p_uf       ,p_telefone ,p_email  ,;
            p_dt_nasc  ,p_cnae    ,p_situacao  ,p_dt_situa ) class cliente
    _Super:new( p_nome     ,p_nm_red  ,p_cpf_cnpj  ,p_cep      ,p_endereco ,p_compl  ,;
                p_bairro   ,p_cidade  ,p_cod_ibge  ,p_uf       ,p_telefone ,p_email  ,;
                p_dt_nasc  ,p_cnae    ,p_situacao  ,p_dt_situa )

return self

method grava_cliente() class cliente

    Local aSA1          := array(0)
    Local aAI0          := array(0)
    Local cCodigo       := ''
    Local cLoja         := ''
    Local cAliasSQL     := ''

    Private lMsErroAuto := .F.

    IF empty(self:cpf_cnpj)
        conout("CLASS_CLIENTE " + time() + " - CNPJ NAO INFORMADO")
        return .F.
    EndIF    

    IF SA1->(dbSetOrder(3),dbSeek(xFilial(alias())+self:cpf_cnpj))
        conout("CLASS_CLIENTE " + time() + " - CLIENTE CADASTRADO ANTERIORMENTE - COD/LOJA: " + SA1->(A1_COD+A1_LOJA))
        self:codigo := SA1->A1_COD
        self:loja   := SA1->A1_LOJA
        return .F.
    EndIF    

    cAliasSQL           := getNextAlias()

    BeginSQL alias cAliasSQL
        SELECT * FROM %table:SA1% SA1
        WHERE SA1.%notdel%
        AND substr(A1_CGC,1,8) = %exp:(substr(self:cpf_cnpj,1,8))%
        ORDER BY A1_COD,A1_LOJA
    EndSQL

    (cAliasSQL)->(dbEval({|| cCodigo := A1_COD, cLoja := A1_LOJA}),dbCloseArea())

    IF empty(cCodigo)
        
        cCodigo := getSxeNum("SA1","A1_COD")
        cLoja   := "01"

        While SA1->(dbSetOrder(1),dbSeek(xFilial(alias())+cCodigo+cLoja))
            confirmSX8()
            cCodigo := getSxeNum("SA1","A1_COD")
        End    

    Else

        SA1->(dbSetOrder(1),dbSeek(xFilial(alias())+cCodigo+cLoja))
        cLoja   := soma1(cLoja)
        
    EndIF 

    aadd(aSA1,{"A1_COD"     ,cCodigo             ,})
    aadd(aSA1,{"A1_LOJA"    ,cLoja               ,}) 
    aadd(aSA1,{"A1_NOME"    ,self:nome           ,})
    aadd(aSA1,{"A1_NREDUZ"  ,self:nome_reduzido  ,}) 
    aadd(aSA1,{"A1_CGC"     ,self:cpf_cnpj       ,})
    aadd(aSA1,{"A1_TIPO"    ,"F"                 ,})
    aadd(aSA1,{"A1_PESSOA"  ,"J"                 ,})
    aadd(aSA1,{"A1_END"     ,self:endereco       ,}) 
    aadd(aSA1,{"A1_BAIRRO"  ,self:bairro         ,}) 
    aadd(aSA1,{"A1_EST"     ,self:uf             ,})
    aadd(aSA1,{"A1_MUN"     ,self:cidade         ,})  
    aadd(aSA1,{"A1_COD_MUN" ,self:cod_ibge       ,})   
    aadd(aSA1,{"A1_CEP"     ,self:cep            ,})
    aadd(aSA1,{"A1_EMAIL"   ,self:email          ,})
    aadd(aSA1,{"A1_TEL"     ,self:telefone       ,})
    aadd(aSA1,{"A1_CNAE"    ,self:cnae           ,})   
    aadd(aSA1,{"A1_COMPLEM" ,self:complemento    ,})
    aadd(aSA1,{"A1_DTNASC"  ,self:data_nascimento,})

    aadd(aAI0,{"AI0_SALDO"  ,0                   ,})

    lMsErroAuto := .F.

    msExecAuto({|a,b,c| CRMA980(a,b,c)},aSA1,3,aAI0)

    IF lMsErroAuto
        mostraerro()
        return .F.
    EndIF

    self:codigo := SA1->A1_COD
    self:loja   := SA1->A1_LOJA    

return .T.
