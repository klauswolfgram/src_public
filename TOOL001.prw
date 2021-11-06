#include 'totvs.ch'

/*/{Protheus.doc} User Function TOOL001
    Programa para uso em treinamento advpl.
    @type  User Function
    @author Klaus Wolfgram
    @since 06/11/2021
    @version 1.0
    @return lret, Boolean, Indica se deve continuar a execucao ou nao
    @see https://github.com/klauswolfgram/src_public.git
    @see https://tdn.totvs.com/pages/viewpage.action?pageId=22480523    (nomeação de arquivos       )
    @see https://tdn.totvs.com/display/tec/AdvPL+-+Compiler+Directives  (diretivas de compilacao    )
    @see https://tdn.totvs.com/display/tec/Estrutura+de+um+Programa     (estrutura de um programa   )
    @see https://tdn.totvs.com/pages/viewpage.action?pageId=6063098     (escopo de variaveis        )
    @see https://tdn.totvs.com/display/tec/Tipos+de+Dados               (tipos de dados             )
    @see https://tdn.totvs.com/display/tec/Operadores+Comuns            (operadores da linguagem    )

    @history 06/11/2021, Klaus Wolfgram, Construcao inicial do programa
    /*/

    /*/Escopo de funcoes

        Function        -> Desenvolvimento de funcoes pela fabrica da Totvs
        Main Function   -> Indica entre outras coisas, os nomes dos módulos
        User Function   -> Escopo definido para desenvolvimentos dos clientes
        Static Function -> Funcao auxiliar executada apenas no proprio arquivo onde é declarada.

    /*/

    /*/Escopo de variaveis
        Local           -> Indica que a variavel estara disponivel apenas na funcao onde foi declarada.
        Private         -> Indica que a variavel estara disponivel na funcao que foi declarada e em toda funcao acionada a partir dela
        Static          -> Indica que a variavel atua como se fosse uma constante
        Public          -> A variavel fica disponivel enquanto a Thread em que ela foi criada existir.
        /*/

    /*/Tipos de variaveis
        Caracter        -> "C"
        Numeric         -> "N"
        Logical         -> "L"
        Array           -> "A"
        Object          -> "O"
        Code Block      -> "B"
        Data            -> "D"
        Nil             -> "U"
    /*/

    /*/Operadores da linguagem (Princiais)

        -> Atribuicao 
            cTexto      := "TESTE"
            nSoma       := 10
            nSoma       += 5
            nSoma       -= 2

            cTexto      += "NOVO TESTE"

        -> Numericos
            + soma
            - subtracao
            / divisao
            % resto
            ^ exponenciacao
            = igualdade
            <> diferenca
            != diferenca

        -> Texto/data
            + concatenacao
            $ esta contido     
            = igualdade
            == exatamente igual
            <> diferenca
            != fiferenca

        Logico
            > maior
            < menor
            >= maior ou igual
            <= menor ou igual

            .And. 
            .Or. 
            .Not. !   
    /*/
    
User Function TOOL001()

    //-- Area de ajustes iniciais
    Local lRet      := .F.
    Local cSQL      := '0'
    Local cAliasSQL := ''
    Local x         := 0
    Local nTotal    := 0 //somar(10,30)
    Local aDados    := {}
    Local dDataHJ   := stod('')
    Local bField    := {|| x := 1}
    Local oObjct    := nil

    Static cTitulo  := 'FERRAMENTA DE APOIO ADVPL'

    alert(cTitulo)

    /*/
    Private lMsErroAuto := .F.
    mata010(aDados,3)
    /*/

    nTotal := somar(10,30)

    //-- Corpo do programa
    cSQL := ''
    cAliasSQL := getNextAlias()

    For x := 1 To 10

    Next

    //-- Area de encerramento da funcao
    IF empty(cSQL)

        lret := .F.
        return lret

    EndIF

    IF empty(cAliasSQL)

        return .F.

    EndIF    
            
    
Return lret

//-- Funcao auxiliar 
Static Function somar(x,y)

    Local nSoma := x + y   

return nSoma
