#include 'totvs.ch'

function u_app001

    Local cBaseCSV  := 'l:/totvs/arquivos/base_cnpj.csv'
    Local cBuffer   := ''
    Local aBuffer   := array(0)
    Local aCSV      := array(0)
    Local nHdl      := FT_FUSE(cBaseCSV)    

    IF nHdl < 0
        fwAlertError('Arquivo ' + cBaseCSV + ' nao encontrado','Erro')
        return .F.
    EndIF   

    FT_FGOTOP()

    While .not. FT_FEOF()

        cBuffer := FT_FREADLN()
        aBuffer := strToKArr(cBuffer,',')

        IF Len(aBuffer) > 1
            aadd(aCSV,aBuffer[1])
        EndIF

        FT_FSKIP()

    Enddo 

    FT_FUSE()

    processa({|| app001(aCSV)},"Gerando base de dados","Aguarde...")

return  

Static Function app001(aCSV)

    Local oCliFor 
    Local x
    Local lCliente
    Local lFornece

    procregua(Len(aCSV))

    For x := 1 To Len(aCSV)

        incproc()
        sleep(2000)
        
        oCliFor := fornecedor():new()
        
        oCliFor:cpf_cnpj := aCSV[x]
        oCliFor:get_dados_cadastrais()

        IF empty(oCliFor:nome)
            Loop
        EndIF

        lCliente := oCliFor:grava_cliente()
        lFornece := oCliFor:grava_fornecedor()

    Next

return
