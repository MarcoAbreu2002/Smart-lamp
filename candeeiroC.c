#include <reg51.h>
/*
	Considerando o led com uma frequência de 500 hz => f = 1/T => T = 1/500 => 0.002 s , ou seja, o led demora 0.002s a atingir a potência máxima
*/
#define SpaceClaps 2500 //timer = 0.2ms -> fimTempo=2500*0.2ms=500ms
#define fim	10     //timer = 0.2ms -> fimTempo=10*0.2ms=20ms
#define setentaCinco 7
#define cinquenta 4
#define vinteCinco 2


sbit led = P1^0; //output, pin onde se localiza o led
sbit S1 = P1^1; //input, pin onde se localiza o botao on/off
//sbit S2 = P3^2;
//sbit microfone = P3^3;

bit S2 = 0; //bit responsável pela deteção do botão S2
bit microfone = 0; //bit responsável pela deteção do microfone
int palma = 0; //número de palmas até o momento
unsigned char conta = 0; // variável incrementada a cada ciclo de 200 us para auxilixar na contagem de tempo para gerir a intensidade do led
int segundosPalmas = 0; //incrementada a cada 0,5 segundos usado para auxilixar no tempo entre cada palma
int auxsegundosPalmas = 0; // variável incrementada a cada ciclo de 200 us para auxilixar na contagem de tempo para gerir o tempo das palmas 
int botao1 = 0; //variavel utilizada como auxiliar na hora de ligar o led, ou seja, faz com que o led permaneça ativo mesmo após deixar de pressinar o botão
int flag = 0; //variavel utilizada como auxiliar no densidade do led, guardando quantas vezes o botão foi pressionado
int flag3 = 0;//variavel utilizada como auxiliar no microfone, guardando quantas vezes o microfone foi ativo
int palma1 = 0;//flag para 1 palma 
int palma2 = 0;//flag para a 2 palma
unsigned char intensidade = fim; //inicializa a intensidade do led a 100%
//declaração de funções
void Init(void);

void Init(void){
	S1 = 1; //inicializa o valor do botão S1 a 1 ou seja desligado
	led = 0; //inicializa o led a 0 ou seja desligado
//Configuração do restito IE
	EA = 1; //ativa interrupções globais
	ET0 = 1; //ativa interrupção timer 0
	EX0 = 1; //ativa interrupção externa 0
	EX1 = 1; //ativa interrupção externa 1	   
	
//Configuracao Registo TMOD
// 256 us - 56 us = 200 us
// 56 = 0x38

	TMOD &= 0xF0; //limpa os 4 bits do timer 0 (8 bits – auto reload) -> timer mode
	TMOD |= 0x02; //modo 2 do timer 0
	
//Configuracao Timer 0
	TH0 = 0x38; //Timer high byte 0 - 200us 
	TL0 = 0x38; //Timer low byte 0
	
//Configuracao Registo TCON
	TR0 = 1; //comeca o timer 0 ->Time Run -> run control flag
	IT0 = 1; //interrupção externa 0 ativa a falling edge
	IT1	= 1; //interrupção externa 1 ativa a falling edge
}

//interrupcao externa
void External0_ISR(void) interrupt 0
{
	S2 = 1; //interrupção externa, ativa quando pressionado o botão S2 ativando a flag S2 e "chamando" a função referente à mesma
}

void Timer0_ISR(void)interrupt 1{
	conta++; //incrementada a cada 200 microsegundos
	if(auxsegundosPalmas > 2499){ //se já passaram 0.5s entre a primeira palma => 2500 * 200 microsegundos
		segundosPalmas++; //incrementa indicando que ja se passou 0.5 segundos
		auxsegundosPalmas = 0;//reset da variável
	}else{
		auxsegundosPalmas++;
	}
	/*if(segundosPalmas >= 22){//após 11 segundos sem ativação no microfone, reseta a variável segundosPalmas
	segundosPalmas = 0;
	}*/
}

void External2_ISR(void) interrupt 2
{

	microfone = 1 ;//interrupção externa, ativa quando ativado o microfone ativando a flag microfone e "chamando" a função referente à mesma
}


void main (void){

	Init();
	
	while(1){ //loop infinito
		
		if(S1 == 0){ //se o botão S1 foi pressionado
			if(botao1 == 0){ //se o auxiliar está a 0
				led = 1; //liga o led
				botao1 = 1; //coloca o auxiliar a 1 permanecendo o led a 1 
			}else{
				botao1 = 0;
				led = 0;//desliga o led
			}
		while(S1 == 0){}//permanece neste estado até de ativar novamente S1
		}


//deteta o botao pressionado e modifica o valor de intensidade

		if(S2 == 1 && led == 1){//se o botão S1 foi pressionado e o led está ligado
				flag++; //incrementa a flag indicando quantas vezes o botão foi apertado
		}
		if(flag != 0){//se for diferente de 0 quer dizer que o botão foi apertado
					
		if(conta == intensidade){ //se a conta for igual à intensidade quer dizer que chegou à intensidade desejada colocando o led a 0
			led = 0; 
		}
		
		if(conta == 10){//se a conta for igual a 10 quer dizer que chegou ao final do periodo (T)
			conta = 0;
			led = 1;
		}
		
		if(flag==5){//chegou ao final das intensidades pois só existem 4
			flag = 0;
			S2 = 0;
		}
	
			switch(flag){
				case 1:
					intensidade = setentaCinco;
					break;
				case 2:
					intensidade = cinquenta;
				break;
				case 3:
					intensidade = vinteCinco;
				break;
				case 4:
					intensidade = fim;
				break;
				default:
					break;
					}
			S2 = 0;
				}
			


	if(segundosPalmas>=40 && palma == 1 ){//se a primeira palma já aconteceu e já passaram 10 segundos então reseta as variáveis
			palma = 0;
			microfone = 0;
		  palma1 = 0;
			palma2 = 0;
    }

	
	if(microfone==1){
		flag3++;
	}
	
	if(flag3 != 0){
		if(palma1 == 0){
			segundosPalmas = 0;
			palma = 1;
			microfone = 0;
			flag3 = 0;
			palma1 = 1;
	}
		if(palma2 == 0){
		if(segundosPalmas>2){ //se já passou 1 segundo desta a primeira palma
			palma =  2;
			microfone = 0;
			palma2 = 1;
		}
	}

	}
		
			if(palma == 2 && led==1){//se foram dadas 2 palmas e o led estava ligado => desliga led e reseta variaveis
				palma = 0;
				led = 0;
				microfone = 0;
				palma1 = 0;
				palma2 = 0;
				flag3 = 0;
			}
			if(palma==2 && led==0){//se foram dadas 2 palmas e o led estava desligado => liga led e reseta variaveis
				palma = 0;
				led = 1;
				microfone = 0;
				palma1 = 0;
				palma2 = 0;
				flag3 = 0;
			}
			if(palma == 3 && led==1){
					do{
					palma = 0;
					microfone = 0;
					led = ~led;
					}while(segundosPalmas>75);
					led = 1;
			}
}
}

