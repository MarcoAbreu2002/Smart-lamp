;Constantes


fim EQU 10 //intensidade máxima
setentacinco EQU 7 
cinquenta EQU 4
vintecinco EQU 2	
led EQU P1^0   ;output, pin onde se localiza o led
S1 EQU P1^1    ;input, pin onde se localiza o botao on/off
S2 EQU 0    ;responsável pela deteção do botão S2
microfone EQU 0  ;responsável pela deteção do microfone
zero EQU 0
menosum EQU -1
conta EQU 0 ;variável incrementada a cada ciclo de 200 us para auxilixar na contagem de tempo para gerir a intensidade do led
palma EQU 0 ;número de palmas até o momento
palma1 EQU 0 ;flag para 1 palma 
palma2 EQU 0 ;flag para a 2 palma
intensidade EQU fim ;inicializa a intensidade do led a 100%
meiosegundo EQU 2500 ;se já passaram 0.5s entre a primeira palma => 2500 * 200 microsegundos
segundosPalmasMax EQU 22
auxsegundosPalmas EQU 0
segundosPalmas EQU	0


CSEG AT 0000h ;localização inicio código
	JMP inicio
CSEG AT 0003h ;localização interrupção externa 0
	JMP External0_ISR
CSEG AT 000Bh ;localização timer 0
	JMP Timer0_ISR
CSEG AT 0013h;localização interrupção externa 1
	JMP External2_ISR
CSEG AT 0030h
	inicio:
		MOV SP, #7 ;inicialização Stack pointer
		CALL Init ;chama inicializações
Principal:
 JNB S1, primeiraEtapaON ;botão ON/OFF (S1) pressionado 
 JB microfone, terceiraEtapa ;interrupção externa microfone
 JB S2, segundaEtapa ;interrupção externa S2
 JMP Principal
 
primeiraEtapaON:
	SETB led ;liga o led
	JB S1, primeiraEtapaIncrementa ;se S1=1 salta para 	primeiraEtapaIncrementa
primeiraEtapaIncrementa: ;tem por objetivo manter o led a 1 mesmo apos libertar o botão S1
	JB S1,primeiraEtapaIncrementadois
	JB S2, segundaEtapa ;desligar o led quando está sendo utilizado na etapa dois ou seja intensidade
	JMP primeiraEtapaIncrementa ;espera mudança 

primeiraEtapaIncrementadois:
	JNB S1,primeiraEtapaOFF ;se pressionado novamente quer dizer que quer desligar => se S1==0 desliga
	JB S2, segundaEtapa  ;desligar o led quando está sendo utilizado na etapa dois ou seja intensidade
	JMP primeiraEtapaIncrementadois ;espera mudança
	
primeiraEtapaOFF:
	CLR led
	CLR S1
	JB S1, primeiraEtapaFim
	JMP primeiraEtapaOFF

primeiraEtapaFim:
	JMP Principal
	



segundaEtapa:
	JNB led, fimSegundaEtapa ;se o led estiver desligado nada acontece
	INC R3 ;incremata flag para determinar nível de intensidade => flag==1 => intensidade = setentacinco
	JNB S1, segundaEtapaIntOFF
	JB led, segundaEtapadois ;se led estiver ligado e S1 == 0 então prossegue
	JMP segundaEtapa

segundaEtapadois:
	CJNE R3,#0 ,segundaEtapatres ;se a flag!=0 avança
	JMP segundaEtapa

segundaEtapatres:
	CJNE R2, #intensidade, segundaEtapaquatro ;se conta!=intensidade avança
	CLR led ;desliga led
	
segundaEtapaquatro:	
	CJNE R2, #10,segundaEtapacinco ;se a conta não for igual a 10 quer dizer que ainda não chegou ao final do periodo (T)
	MOV R2, #conta ;reset da variavel
	SETB led ;liga led
	
segundaEtapacinco:
	CJNE R3, #5,segundaEtapaseis ;flag!=5 chegou ao fim das intensidades
	MOV R3, #0 ;reseta flag
	CLR S2 ; reseta S2

segundaEtapaseis:
	CJNE R3, #1,segundaEtapasete ;se flag!=1 
	MOV R4, #setentacinco ;atualiza intensidade
	JMP segundaEtapadez ;break

segundaEtapasete:
	CJNE R3, #2,segundaEtapaoito ;se flag!=2 
	MOV R4, #cinquenta ;atualiza intensidade
	JMP segundaEtapadez;break
	
segundaEtapaoito:
	CJNE R3, #3,segundaEtapanove ;se flag!=3
	MOV R4, #vintecinco ;atualiza intensidade
	JMP segundaEtapadez;break
	
segundaEtapanove:
	CJNE R3, #4,fimSegundaEtapa ;se flag!=4
	MOV R4, #fim ;;atualiza intensidade
	JMP segundaEtapadez ;break
	
segundaEtapadez:
	CLR S2 ;reseta S3

fimSegundaEtapa:
	JMP segundaEtapa

segundaEtapaIntOFF:
	CLR led ;desliga led
	CLR S1 ;desliga S1
	JB S1, primeiraEtapaFim ;se S1==1 desliga
	JMP primeiraEtapaOFF
	
segundaEtapaFim:
	JMP Principal
	
	

terceiraEtapaReset:
	CJNE R1, #21, terceiraEtapa ;Se segundosPalmas já chegou a 21 ou seja já passaram 10 segundos sem palmas
	CLR palma ;atualiza palma para 0
	SETB microfone ;coloca mic a 1
	CLR palma1 ;coloca palma1 a 0
	CLR palma2; coloca palma2 a 0
terceiraEtapa:
	INC R5; incrementa flag3
	
terceiraEtapadois:
	CJNE R5,#0 ,terceiraEtapatres ;se a flag for diferente de 0 ou seja mic foi ativado
	
	
terceiraEtapatres:
	CJNE R6, #0,terceiraEtapaquatro ; se palma1 ==0 ou seja se ainda não aconteceu a primeira palma
	MOV R2, #palma ; coloca informação sobre o nº de palmas até o momento em R2
	INC palma ; incrementa palma
	CLR microfone ; reseta mic
	MOV R5, #0 ; reseta flag3
	MOV R6, #1 ; incrementa palma1
	CJNE R1, #9,terceiraEtapatres ;se segundosPalmas<9 permanece
	JMP terceiraEtapaquatro
	

terceiraEtapaquatro:
	CJNE R7, #0,terceiraEtapacinco ; se palma2 ==0 ou seja se ainda não aconteceu a segunda palma
	INC palma ; incrementa palma
	CLR microfone ; reseta mic
	MOV R5, #0 ; reseta flag3
	MOV R6, #1 ; incrementa palma1
	CJNE R1, #11,terceiraEtapaquatro ;se segundosPalmas>11 permanece
	CJNE R1, #18,terceiraEtapaquatro ;se segundosPalmas<19 permanece
	JMP terceiraEtapacinco
	
terceiraEtapacinco:
	CJNE R2, #2, fimterceiraEtapa ;se palmas==2 se não for passa para o fim
	JB led, terceiraEtapacincoDesliga ;se o led está ligado então passa para a rotina de desligar
	JNB led, terceiraEtapacincoLiga ;se o led estã desligado então passa para a rotina de ligar

terceiraEtapacincoDesliga:		;
	CLR palma					;Desliga led e reseta as variáveis
	CLR led						;
	CLR microfone				;
	CLR palma1
	CLR palma2
	JMP fimterceiraEtapa

terceiraEtapacincoLiga:			;
	CLR palma					;Liga led e reseta variáveis	
	SETB led					;
	CLR microfone				;
	CLR palma1
	CLR palma2
	JMP fimterceiraEtapa
	

fimterceiraEtapa:
	MOV R2, #conta
	JMP Principal




		
Init:
	MOV R0, #auxsegundosPalmas ;colocar valor da variável incrementada a cada ciclo de 200 us para auxilixar na contagem de tempo para gerir o tempo das palmas em R0
	MOV R1, #segundosPalmas ;colocar valor da incrementada a cada 0,5 segundos usado para auxilixar no tempo entre cada palma me R1
	MOV R2,#conta ; colocar valor da variável incrementada a cada ciclo de 200 us para auxilixar na contagem de tempo para gerir a intensidade do led em R2
	MOV R4, #intensidade ;colocar valor da intesidade em R4
	MOV R6, #palma1 
	MOV R7, #palma2
	CLR led ; inicializa o led a 0
	SETB S1 ; inicializa S1 a 1 ou seja não pressionado
	;CLR S2
	;CLR microfone
	MOV IE, #10000111b ;inicialização do IE
	MOV TMOD, #00000010b ;inicialização do TMOD no modo 2 do timer 0
	MOV TL0, #0x38 ;// 256 us - 56 us = 200 us // 56 = 0x38
	MOV TH0, #0x38 ;
	SETB IT0 ;iniciar interrupção externa 0
	SETB IT1 ;iniciar interrupção externa 1
	SETB TR0 ;iniciar timer 0
	RET
	
	
Timer0_ISR:
	INC R2 ; incrementar conta
	INC R0 ;incrementa auxsegundosPalmas
	CJNE R1, #22, TimerFim ;Se segundospalmas não for 22 salta para o fim  
	MOV R1, #0 ;reseta segundospalmas
	CJNE R0, #2500, TimerFim  ;Se auxsegundosPalmas não for 2500 salta para o fim  
	INC R1 ;incrementa segundospalmas
	MOV R0, #0 ; reseta auxsegundosPalmas
	RETI
timerFim:
	RETI
	

External0_ISR:
	SETB S2 ;inicializa flag S2
	RETI ;volta da interrupção externa

External2_ISR:
	SETB microfone ; inicializa flag microfone 
	RETI; volta da interrupção externa

END
