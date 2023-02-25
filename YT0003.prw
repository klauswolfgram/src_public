#include 'totvs.ch'

/*/{Protheus.doc} YT0003
    Gera codigo para cliente/fornecedor baseado no CNPJ.
    @type  User Function 
    @author Klaus Wolfgram
    @since 25/02/2023
    @version 1.0
    /*/
User Function YT0003

    Local cCampo := readvar()
    Local cCGC   := &(cCampo)

    IF "A1_CGC" $ cCampo
        fnGetSA1(cCGC) //-- Gera codigo e loja para cadastro de clientes
    ElseIF "A2_CGC" $ cCampo
        fnGetSA2(cCGC) //-- Gera codigo e loja para cadastro de fornecedores
    EndIF    

    //-- consulta os demais dados do cadastro
    U_YT0002(cCGC)      
    
Return .T.

/*/{Protheus.doc} fnGetSA1
    Gera codigo e loja para cadastro de clientes
    @type  Static Function
    /*/
Static Function fnGetSA1(cCGC)

    Local aAreaSA1 := SA1->(getArea())
    Local cAliasSQL:= ''
    Local cCodigo  := ''
    Local cLoja    := ''

    //-- Se existir registro de cadastro do CNPJ existente, utiliza o mesmo codigo e incrementa a loja
    IF SA1->(dbSetOrder(3),dbSeek(xFilial(alias())+cCGC))

        cCodigo     := SA1->A1_COD
        SA1->(dbSetOrder(1),dbSeek(xFilial(alias())+cCodigo))

        While .not. SA1->(eof()) .and. SA1->(A1_FILIAL+A1_COD) == xFilial('SA1')+cCodigo
            cLoja   := SA1->A1_LOJA
            SA1->(dbSkip())
        Enddo

        cLoja       := soma1(cLoja)

        M->A1_COD   := cCodigo
        M->A1_LOJA  := cLoja

        restArea(aAreaSA1)
        return

    EndIF

    //-- Se o registro do CNPJ nao existir, e caso o tamanho indique que se trata de um CPF, gera um novo codigo com getSxeNum()
    IF Len(cCGC) <= 11
        
        cCodigo     := getSxeNum('SA1','A1_COD')
        cLoja       := '01'

        M->A1_COD   := cCodigo
        M->A1_LOJA  := cLoja

        restArea(aAreaSA1)
        return

    EndIF   

    //-- Procura a base do CNPJ no cadastro de fornecedores utilizando consulta SQL
    cAliasSQL       := getNextAlias() 

    BeginSQL alias cAliasSQL
        SELECT A1_CGC, A1_COD, A1_LOJA, A1_NOME, A1_NREDUZ
        FROM %table:SA1% SA1
        WHERE SA1.%notdel%
        AND A1_FILIAL = %exp:xFilial('SA1')%
        AND LEFT(A1_CGC,8) = %exp:substr(cCGC,1,8)%
        ORDER BY A1_COD, A1_LOJA
    EndSQL 

    cCodigo         := ''
    cLoja           := ''

    (cAliasSQL)->(dbEval({|| cCodigo := A1_COD, cLoja := A1_LOJA}),dbCloseArea())

    IF empty(cCodigo)

        cCodigo     := getSxeNum('SA1','A1_COD')
        cLoja       := '01'    
        
        M->A1_COD   := cCodigo
        M->A1_LOJA  := cLoja

        restArea(aAreaSA1)
        return

    EndIF    

    cLoja           := soma1(cLoja)  

    M->A1_COD       := cCodigo
    M->A1_LOJA      := cLoja     

    restArea(aAreaSA1)
    
Return 

/*/{Protheus.doc} fnGetSA2
    Gera codigo e loja para cadastro de fornecedores
    @type  Static Function
    /*/
Static Function fnGetSA2(cCGC)

    Local aAreaSA2 := SA2->(getArea())
    Local cAliasSQL:= ''
    Local cCodigo  := ''
    Local cLoja    := ''

    //-- Se existir registro de cadastro do CNPJ existente, utiliza o mesmo codigo e incrementa a loja
    IF SA2->(dbSetOrder(3),dbSeek(xFilial(alias())+cCGC))

        cCodigo     := SA2->A2_COD
        SA2->(dbSetOrder(1),dbSeek(xFilial(alias())+cCodigo))

        While .not. SA2->(eof()) .and. SA2->(A2_FILIAL+A2_COD) == xFilial('SA2')+cCodigo
            cLoja   := SA2->A2_LOJA
            SA2->(dbSkip())
        Enddo

        cLoja       := soma1(cLoja)

        M->A2_COD   := cCodigo
        M->A2_LOJA  := cLoja

        restArea(aAreaSA2)
        return

    EndIF

    //-- Se o registro do CNPJ nao existir, e caso o tamanho indique que se trata de um CPF, gera um novo codigo com getSxeNum()
    IF Len(cCGC) <= 11
        
        cCodigo     := getSxeNum('SA2','A2_COD')
        cLoja       := '01'

        M->A2_COD   := cCodigo
        M->A2_LOJA  := cLoja

        restArea(aAreaSA2)
        return

    EndIF   

    //-- Procura a base do CNPJ no cadastro de fornecedores utilizando consulta SQL
    cAliasSQL       := getNextAlias() 

    BeginSQL alias cAliasSQL
        SELECT A2_CGC, A2_COD, A2_LOJA, A2_NOME, A2_NREDUZ
        FROM %table:SA2% SA2
        WHERE SA2.%notdel%
        AND A2_FILIAL = %exp:xFilial('SA2')%
        AND LEFT(A2_CGC,8) = %exp:substr(cCGC,1,8)%
        ORDER BY A2_COD, A2_LOJA
    EndSQL 

    cCodigo         := ''
    cLoja           := ''

    (cAliasSQL)->(dbEval({|| cCodigo := A2_COD, cLoja := A2_LOJA}),dbCloseArea())

    IF empty(cCodigo)

        cCodigo     := getSxeNum('SA2','A2_COD')
        cLoja       := '01'    
        
        M->A2_COD   := cCodigo
        M->A2_LOJA  := cLoja

        restArea(aAreaSA2)
        return

    EndIF    

    cLoja           := soma1(cLoja)  

    M->A2_COD       := cCodigo
    M->A2_LOJA      := cLoja     

    restArea(aAreaSA2)

Return 
