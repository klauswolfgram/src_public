#include 'totvs.ch'

class fornecedor from cliente

    method new() constructor
    method grava_fornecedor()

endclass

method new( p_nome     ,p_nm_red  ,p_cpf_cnpj  ,p_cep      ,p_endereco ,p_compl  ,;
            p_bairro   ,p_cidade  ,p_cod_ibge  ,p_uf       ,p_telefone ,p_email  ,;
            p_dt_nasc  ,p_cnae    ,p_situacao  ,p_dt_situa ) class fornecedor
    _Super:new( p_nome     ,p_nm_red  ,p_cpf_cnpj  ,p_cep      ,p_endereco ,p_compl  ,;
                p_bairro   ,p_cidade  ,p_cod_ibge  ,p_uf       ,p_telefone ,p_email  ,;
                p_dt_nasc  ,p_cnae    ,p_situacao  ,p_dt_situa )            

return self

method grava_fornecedor() class fornecedor

    Local aSA2          := array(0)
    Local cCodigo       := ''
    Local cLoja         := ''
    Local cAliasSQL     := ''

    Private lMsErroAuto := .F.

    self:codigo         := ''
    self:loja           := ''

    IF empty(self:cpf_cnpj)
        conout("CLASS_FORNECEDOR " + time() + " - CNPJ NAO INFORMADO")
        return .F.
    EndIF    

    IF SA2->(dbSetOrder(3),dbSeek(xFilial(alias())+self:cpf_cnpj))
        conout("CLASS_FORNECEDOR " + time() + " - FORNECEDOR CADASTRADO ANTERIORMENTE - COD/LOJA: " + SA2->(A2_COD+A2_LOJA))
        self:codigo := SA2->A2_COD
        self:loja   := SA2->A2_LOJA
        return .F.
    EndIF    

    cAliasSQL           := getNextAlias()

    BeginSQL alias cAliasSQL
        SELECT * FROM %table:SA2% SA2
        WHERE SA2.%notdel%
        AND substr(A2_CGC,1,8) = %exp:(substr(self:cpf_cnpj,1,8))%
        ORDER BY A2_COD,A2_LOJA
    EndSQL

    (cAliasSQL)->(dbEval({|| cCodigo := A2_COD, cLoja := A2_LOJA}),dbCloseArea())

    IF empty(cCodigo)
        cCodigo := getSxeNum("SA2","A2_COD")
        cLoja   := "01"

        While SA2->(dbSetOrder(1),dbSeek(xFilial(alias())+cCodigo+cLoja))
            confirmSX8()
            cCodigo := getSxeNum("SA2","A2_COD")
        End         
    Else
        SA2->(dbSetOrder(1),dbSeek(xFilial(alias())+cCodigo+cLoja))
        cLoja   := soma1(cLoja)
    EndIF 

    aadd(aSA2,{"A2_COD"     ,cCodigo             ,})
    aadd(aSA2,{"A2_LOJA"    ,cLoja               ,}) 
    aadd(aSA2,{"A2_NOME"    ,self:nome           ,})
    aadd(aSA2,{"A2_NREDUZ"  ,self:nome_reduzido  ,}) 
    aadd(aSA2,{"A2_CGC"     ,self:cpf_cnpj       ,})
    aadd(aSA2,{"A2_TIPO"    ,"J"                 ,})
    aadd(aSA2,{"A2_END"     ,self:endereco       ,}) 
    aadd(aSA2,{"A2_BAIRRO"  ,self:bairro         ,}) 
    aadd(aSA2,{"A2_EST"     ,self:uf             ,})
    aadd(aSA2,{"A2_MUN"     ,self:cidade         ,})  
    aadd(aSA2,{"A2_COD_MUN" ,self:cod_ibge       ,})   
    aadd(aSA2,{"A2_CEP"     ,self:cep            ,})
    aadd(aSA2,{"A2_EMAIL"   ,self:email          ,})
    aadd(aSA2,{"A2_TEL"     ,self:telefone       ,})
    aadd(aSA2,{"A2_CNAE"    ,self:cnae           ,})   
    aadd(aSA2,{"A2_COMPLEM" ,self:complemento    ,})
    aadd(aSA2,{"A2_DTNASC"  ,self:data_nascimento,})

    lMsErroAuto := .F.

    msExecAuto({|a,b| MATA020(a,b)},aSA2,3)

    IF lMsErroAuto
        mostraerro()
        return .F.
    EndIF

    self:codigo := SA2->A2_COD
    self:loja   := SA2->A2_LOJA

return .T.
