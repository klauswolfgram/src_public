#include 'totvs.ch'

class pessoa

    //-- definicao dos atributos
    data nome
    data nome_reduzido
    data cpf_cnpj
    data cep
    data endereco
    data complemento
    data bairro
    data cidade
    data cod_ibge
    data uf
    data telefone
    data email
    data data_nascimento
    data cnae
    data situacao
    data data_situacao
    data codigo
    data loja

    //-- definicao dos metodos
    method new() constructor
    method get_dados_cadastrais()
    
endclass

method new( p_nome     ,p_nm_red  ,p_cpf_cnpj  ,p_cep      ,p_endereco ,p_compl  ,;
            p_bairro   ,p_cidade  ,p_cod_ibge  ,p_uf       ,p_telefone ,p_email  ,;
            p_dt_nasc  ,p_cnae    ,p_situacao  ,p_dt_situa )class pessoa

    default p_nome              := ''
    default p_nm_red            := ''
    default p_cpf_cnpj          := ''
    default p_cep               := ''
    default p_endereco          := ''
    default p_compl             := ''
    default p_bairro            := ''
    default p_cidade            := ''
    default p_cod_ibge          := ''
    default p_uf                := ''
    default p_telefone          := ''
    default p_email             := ''
    default p_dt_nasc           := stod('')
    default p_situacao          := ''
    default p_dt_situa          := stod('')
    default p_cnae              := ''

    self:nome                   := p_nome
    self:nome_reduzido          := p_nm_red
    self:cpf_cnpj               := p_cpf_cnpj
    self:cep                    := p_cep
    self:endereco               := p_endereco
    self:complemento            := p_compl
    self:bairro                 := p_bairro
    self:cidade                 := p_cidade
    self:cod_ibge               := p_cod_ibge
    self:uf                     := p_uf
    self:telefone               := p_telefone
    self:email                  := p_email
    self:data_nascimento        := p_dt_nasc    
    self:cnae                   := p_cnae
    self:situacao               := p_situacao
    self:data_situacao          := p_dt_situa
    self:codigo                 := ''
    self:loja                   := ''

return self

method get_dados_cadastrais() class pessoa

    Local cURL     := 'https://www.receitaws.com.br/v1/cnpj/'
    Local oJsonRet := nil
    Local xJsonRet := nil
    Local xRet     := nil

    Local cCNPJ    := strtran(strtran(strtran(self:cpf_cnpj,".",""),"-",""),"/","")
    cURL           += cCNPJ

    cTxtRet         := httpGet(cURL)
    oJsonRet        := jsonObject():new()
    xJsonRet        := oJsonRet:fromJson(fwNoAccent(cTxtRet)) 

    IF valtype(xJsonRet) <> 'U' 
        return xRet
    EndIF

    cNome        := oJsonRet:getJsonText('nome'               );  cNome        := fwNoAccent(upper(iif(cNome    == 'null','',cNome   )))
    cNomeRe      := oJsonRet:getJsonText('fantasia'           );  cNomeRe      := fwNoAccent(upper(iif(cNomeRe  == 'null','',cNomeRe )))
    cDtAber      := oJsonRet:getJsonText('abertura'           );  cDtAber      := fwNoAccent(upper(iif(cDtAber  == 'null','',cDtAber )))
    cBairro      := oJsonRet:getJsonText('bairro'             );  cBairro      := fwNoAccent(upper(iif(cBairro  == 'null','',cBairro )))
    cCep         := oJsonRet:getJsonText('cep'                );  cCep         := fwNoAccent(upper(iif(cCep     == 'null','',cCep    )))
    cEnd         := oJsonRet:getJsonText('logradouro'         );  cEnd         := fwNoAccent(upper(iif(cEnd     == 'null','',cEnd    )))
    cNrEnd       := oJsonRet:getJsonText('numero'             );  cNrEnd       := fwNoAccent(upper(iif(cNrEnd   == 'null','',cNrEnd  )))
    cCidade      := oJsonRet:getJsonText('municipio'          );  cCidade      := fwNoAccent(upper(iif(cCidade  == 'null','',cCidade )))
    cEstado      := oJsonRet:getJsonText('uf'                 );  cEstado      := fwNoAccent(upper(iif(cEstado  == 'null','',cEstado )))
    cCompl       := oJsonRet:getJsonText('complemento'        );  cCompl       := fwNoAccent(upper(iif(cCompl   == 'null','',cCompl  )))
    cTel         := oJsonRet:getJsonText('telefone'           );  cTel         := fwNoAccent(upper(iif(cTel     == 'null','',cTel    )))
    cEmail       := oJsonRet:getJsonText('email'              );  cEmail       := fwNoAccent(upper(iif(cEmail   == 'null','',cEmail  )))    
    cSitua       := oJsonRet:getJsonText('situacao'           );  cSitua       := fwNoAccent(upper(iif(cSitua   == 'null','',cSitua  )))   
    cDtSitu      := oJsonRet:getJsonText('data_situacao'      );  cDtSitu      := fwNoAccent(upper(iif(cDtSitu  == 'null','',cDtSitu )))    

    IF .not. empty(cNrEnd); cEnd := alltrim(cEnd) + ', ' + cNrEnd; EndIF     

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

    IF .not. CC3->(dbSetOrder(1),dbSeek(xFilial(alias())+cCnae))
        cCnae := ''
    EndIF   

    IF empty(cNomeRe)
        cNomeRe := cNome
    EndIF         

    self:nome                   := substr(upper(cNome   ),1,tamSX3('A1_NOME'    )[1])
    self:nome_reduzido          := substr(upper(cNomeRe ),1,tamSX3('A1_NREDUZ'  )[1])       
    self:endereco               := substr(upper(cEnd    ),1,tamSX3('A1_END'     )[1])
    self:complemento            := substr(upper(cCompl  ),1,tamSX3('A1_COMPLEM' )[1])
    self:bairro                 := substr(upper(cBairro ),1,tamSX3('A1_BAIRRO'  )[1])
    self:cidade                 := substr(upper(cCidade ),1,tamSX3('A1_MUN'     )[1])
    self:cod_ibge               := substr(upper(cCodMun ),1,tamSX3('A1_COD_MUN' )[1])
    self:uf                     := substr(upper(cEstado ),1,tamSX3('A1_EST'     )[1])
    self:email                  := substr(upper(cEmail  ),1,tamSX3('A1_EMAIL'   )[1])
    self:telefone               := substr(upper(cTel    ),1,tamSX3('A1_TEL'     )[1])     
    self:cep                    := strtran(strtran(cCep,".",""),"-")       
    self:data_nascimento        := ctod(cDtAber)    
    self:cnae                   := cCnae
    self:situacao               := upper(cSitua)
    self:data_situacao          := ctod(cDtSitu)
    self:codigo                 := ''
    self:loja                   := ''         

return 
