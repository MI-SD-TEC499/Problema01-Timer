# Problema 01 - Timer
# Integrantes: Daniel Costa, Diego Silva e Thiago Menezes

# 1 - Introdução
Com o avanço da tecnologia, inclusive a de construção de transistores, tem sido possibilitado cada vez mais a construção de computadores com menor tamanho, melhor desempenho, incluindo energético, e menor custo. Sistemas embarcados em microcontroladores são utilizados para diversas tarefas de automação e na chamada _Internet of Things_ (IoT).

O problema apresentado a seguir consistiu no desenvolvimento de um temporizador em um microcontrolador Raspberry Pi Zero, utilizando uma linguagem de montagem com arquitetura ARM. O temporizador deve contar com funções básicas de controle do tempo, sendo possível parar e iniciar a temporização, assim como reiniciá-la a partir do tempo inicial.

# 2 - Ambiente e Ferramentas
## 2.1 - Ambiente

O problema foi desenvolvido para funcionar em uma Raspberry Pi Zero, utilizando como periférico de saída um display LCD Hitachi HD44780U (LCD-II) de 16x2. Essa Raspberry possui arquitetura ARMv6 de 32bits.

Para a ambientação com linguagem de montagem, foi utilizada a plataforma web CPULator na versão de arquitetura ARMv7.

Para a emulação do código fora do laboratório, foi utilizado o software QEMU, usando o kernel 4.4.34-jessie e com uma imagem raspbian-jessie para o sistema operacional, ambos disponíveis nesse repositório.
## 2.2 - Outras Ferramentas

Para desenvolvimento do código foram utilizados diferentes editores de texto, como o GNU Nano e o Visual Studio Code.

# 3 - Desenvolvimento
**3.1 - Nanosleep:**

```s
.macro nanoSleep time		@Macro responsavel por definir um intervalo de tempo
        LDR R0,=timespecsec	@Parâmetro fixo para o nano_sleep.
        LDR R1,=\time		@Parâmetro que define o tempo do delay.
        MOV R7, #nano_sleep	@Passa o valor da sys_map para o R7(registrador para chamada de sycalls).
        SVC 0			@Executa a syscall.
.endm
```

O macro em questão é utilizado para fazer o sistema “dormir” durante um tempo pré-determinado sempre que existir a necessidade de esperar um intervalo específico entre instruções, são passados dois argumentos para o macro : 
- `timespecsec` que é um valor fixo.
- `time` que define quanto tempo a execução fica em espera.

Depois é enviado ao R7 o valor da syscall(162), que é executada em seguida.
O `nanosleep` é vital para o funcionamento do display, que precisa de delays específicos entre os conjuntos de instruções.

**3.2 - Usando um pino como output:**

```s
.macro GPIODirectionOut pin
        LDR R2, =\pin 	@ endereço das informações do pino
        LDR R2, [R2]
        LDR R1, [R8, R2]
        LDR R3, =\pin 	@ endereço das informações do pino
        ADD R3, #4 	@ tamanho do shift nas informações
        LDR R3, [R3] 	@ carrega o valor do shift
        MOV R0, #0b111 	@ limpa 3 bits
        LSL R0, R3 	@ dá um shift para a posição
        BIC R1, R0 	@ limpa os 3 bits
        MOV R0, #1 	@ 1 bit to shift into pos
        LSL R0, R3 	@ dá um shift para a posição
        ORR R1, R0 	@ seta o bit
        STR R1, [R8, R2] @ salva no registrador para utilização
.endm
```

Quando um pino é usado, devemos informar se ele vai servir como entrada ou saída, na imagem o pino é setado como output :
- Informamos o endereço base do pino(com base no FSEL referente no datasheet)
- Passamos a posição do primeiro bit reservado para o pino(cada FSEL é responsável por 10 pinos com 3 bits para cada),
- Fazemos um Shift para a posição correta(com base no valor passado), e salvamos o resultado em um registrador.

**3.3 - Ativando um pino:**

```s
.macro GPIOTurnOn pin, value
        MOV R2, R8 	@ endereço do mapeamento
        ADD R2, #setregoffset @ offset necessário nos registradores
        MOV R0, #1 	@ 1 bit para dar o shift para a posição
        LDR R3, =\pin 	@ base da tabela de informações do pino
        ADD R3, #8 	@ offset para o shift
        LDR R3, [R3] 	@ carrega o valor do shift da tabela
        LSL R0, R3 	@ realiza o shift
        STR R0, [R2] 	@ escreve no registrador
	nanoSleep timespecnano150
.endm
```

Após um pino ter sua função definida, ele vai ser ligado de acordo com a necessidade do projeto, seguindo a lógica da macro `GPIODirectionOut`,  começamos passando o endereço armazenado no R8, depois passamos o offset do registrador set1(a diferença entre ligar e desligar o pino é basicamente o offset enviado, set para ligar, e clear para desligar).

**3.4 - Abrindo arquivos e mapeando a memória:**

```s
_start:		
        LDR R0, = fileName		@Carrega o endereço.
        MOV R1, #0x1b0			@Parâmetro para o sys_open.
        ORR R1, #0x006			@Parâmetro para o sys_open.
        MOV R2, R1			@Passando valor retornado para R2.
        MOV R7, #sys_open		@Passa o valor de sys_open para o r7.
        SVC 0				@Executa a syscall.
        MOVS R4, R0			@Armazena o endereço no R4.
	
        LDR R5, =gpioaddr		@Carrega o endereço.
        LDR R5, [R5]		
        MOV R1, #pagelen	        @passa o valor maximo da memória.
        MOV R2, #(prot_read + prot_write)	@Parâmetro para escrita e leitura de arquivos.
        MOV R3, #map_shared		@Parâmetro para que outros processos saibam que a região esta sendo mapeada.
        MOV R0, #0			@Deixa o SO escolher o endereço virtual.
        MOV R7, #sys_map		@Passa o valor da syscall para R7.
        SVC 0				@Executa o mapeamento.
        MOVS R8, R0			@Armazena o endereço virtual em R8.
```

Assim que o programa inicia realizamos o mapeamento de memória, onde recebemos um endereço virtual(com base no endereço físico) para os componentes que vão ser utilizados : 
1. A princípio acessamos o diretório “dev/mem” utilizando a syscall `sys_open` (os valores carregados nos registradores servem como parâmetros para encontrar o endereço correto, depois o `SVC 0` executa a syscall.
2. Armazenamos então o endereço base no R5, e utilizamos algumas constantes como parâmetros, `prot_read` e `prot_write` que permitem a leitura e escrita de arquivos, `map_shared` garante que outros processos saibam que aquela região está sendo mapeada, e `pagelen` é referente ao tamanho separado para a memória, por fim passamos o valor da syscall `sys_map` para o R7, e iniciamos o mapeamento chamando novamente o `SVC 0`.

Com a memória mapeada, começamos a preparação do display:
1. Inicializando os pinos (setando como output):
```s
.macro initPins
	GPIODirectionOut pin1 @Enable
	GPIODirectionOut pin12 @DB4
	GPIODirectionOut pin16 @DB5
	GPIODirectionOut pin20 @DB6
	GPIODirectionOut pin21 @DB7
	GPIODirectionOut pin25 @rs
	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas 
.endm
```



2. Inicializando o display:
Antes de começar a escrever no display, devemos inicializa-lo através de instruções.
- O método se resume em enviar um instruction set, e esperar um tempo especifico:

```s
.macro initializeDisplay
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOn pin12 @On no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano5 @Temporização de 5 milisegundos
```

No código acima enviamos um "1" para o `DB4` e para o `DB5`, depois é estabelecido um delay de 5 nanosegundos.
- Em cada grupo de instruções, definimos quais data bits do display recebem 0 ou 1, isso é feito seguindo a ordem definida no datasheet.
- O processo se repete algumas vezes, mas com valores diferentes em cada `Data Bit`.

**3.5 - Iniciando a contagem:**
Depois que o display for inicializado começamos a contagem de 9 a 0, para isso utilizamos o macro `write9to0` : 

```s
.macro write9to0
	writeDecimal 1, 0, 0, 1 @ escreve o 9

	writeDecimal 1, 0, 0, 0 @ escreve o 8

	writeDecimal 0, 1, 1, 1 @ escreve o 7

	writeDecimal 0, 1, 1, 0 @ escreve o 6

	writeDecimal 0, 1, 0, 1 @ escreve o 5

	writeDecimal 0, 1, 0, 0 @ escreve o 4

	writeDecimal 0, 0, 1, 1 @ escreve o 3

	writeDecimal 0, 0, 1, 0 @ escreve o 2

	writeDecimal 0, 0, 0, 1 @ escreve o 1

	writeDecimal 0, 0, 0, 0 @ escreve o 0
.endm
```

A escrita de dados no display é feita através de um grupo de instruções onde informamos o valor passado a cada data bit(similar a inicialização do display), são dois instruction sets seguindo a ordem informada no datasheet do display, para escrever o numero 5 por exemplo :
1. Enviamos um 0011(`DB7,DB6,DB5,DB4` respectivamente) para os upper bits
2. 0101 para os lower bits.
3. Por fim um pulso no enable. 

```s
.macro writeDecimal d7, d6, d5, d4
	writeNumber @ macro que envia os bits de escrita de números

	GPIOTurnOff pin1 	@ Off no enable
	GPIOTurnOn pin25 	@ On no RS para escrita de dado
	GPIOTurnOn pin1 	@ On no enable para o pulso
	GPIOTurnOnOff pin21, #\d7 @ passa o valor para o DB7
	GPIOTurnOnOff pin20, #\d6 @ passa o valor para o DB6
	GPIOTurnOnOff pin16, #\d5 @ passa o valor para o DB5
	GPIOTurnOnOff pin12, #\d4 @ passa o valor para o DB4
	GPIOTurnOff pin1 	@ Off no enable para enviar os dados
	nanoSleep timespecnano150
	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas
.endm
```

A imagem acima representa o envio dos valores aos lower bits.


**3.6 - GPIO pins:**

```s
pin25:	.word 8    	 @RS
	.word 15
	.word 25
pin1:	.word 0    	@E
	.word 3
	.word 1
```

Nós acessamos os periféricos da placa através da GPIO(General purpose input output), mas para que os pinos utilizados funcionem, é necessário valores especificos, usando o `pin25`(RS) como exemplo , associamos ao `pin25` os valores "8" para utilizarmos o GPSEL2 que controla os pinos 20-29, depois enviamos
um "15", que representa o primeiro dos três bits do pin25 (são 32 bits para o GPSEL2, sendo três para cada pino controlado).

**3.7 - Tipos de instruções utilizadas:**

**Aritmética:**
- `ADD`
- `SUB`
- `MUL`

**Manipulação/movimentação:**
- `LSL`
- `MOV` , `MOVS`
- `STR`
- `LDR`

**Lógica:**
- `ORR`
- `BIC`

# 4 - Testes de Funcionamento 
## 1º Teste: 
Para a testagem do mapeamento realizado foi utilizado um componente LED, para caso o mapeamento correto, executaria o código em que o LED acende e, após um segundo, ele apagar.

## 2º Teste: 
Após verificar o mapeamento com o LED, testamos o Display de LCD, para isso foi utilizadu a exibição de uma letra e de caracteres diversos para verificar o funcionamento.

## 3º Teste:
No terceiro teste foi realizado a contagem de 9 a 0 para exibição no display, utilizando somente uma casa decimal em que após a exibição de um caractere, ele é apagado e o próximo é exibido.

# 5 - Referências
![Raspberry Pi Assembly Language Programming](https://link.springer.com/book/10.1007/978-1-4842-5287-1)

![Manual Display HD44780U (LCD-16x2)](https://www.sparkfun.com/datasheets/LCD/HD44780.pdf)
