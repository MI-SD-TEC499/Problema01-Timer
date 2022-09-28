
.equ pagelen, 4096		@Tamanho da memória
.equ setregoffset, 28		@Offset para o registrador GPSET.
.equ clrregoffset, 40		@Offset para o registrador GPCLR.
.equ prot_read, 1		@Parâmetro para o sys_map.
.equ prot_write, 2		@Parâmetro para o sys_map.
.equ map_shared, 1		@Parâmetro para o sys_map.
.equ sys_open, 5		@Syscall que para abertura de arquivos.
.equ sys_map, 192		@Syscall para o mapeamento.
.equ nano_sleep, 162
.equ level, 0x034

.global _start

.macro nanoSleep time		@Macro responsavel por definir um intervalo de tempo
        LDR R0,=timespecsec	@Parâmetro fixo para o nano_sleep.
        LDR R1,=\time		@Parâmetro que define o tempo do delay.
        MOV R7, #nano_sleep	@Passa o valor da sys_map para o R7(registrador para chamada de sycalls).
        SVC 0			@Executa a syscall.
.endm

.macro GPIODirectionIn pin
        LDR R2, =\pin
        LDR R2, [R2]
        LDR R1, [R8, R2]
        LDR R3, =\pin @ address of pin table
        ADD R3, #4 @ load amount to shift from table
        LDR R3, [R3] @ load value of shift amt
        MOV R0, #0b111 @ mask to clear 3 bits
        LSL R0, R3 @ shift into position
        BIC R1, R0 @ clear the three bits
.endm

.macro GPIODirectionOut pin
        LDR R2, =\pin
        LDR R2, [R2]
        LDR R1, [R8, R2]
        LDR R3, =\pin @ address of pin table
        ADD R3, #4 @ load amount to shift from table
        LDR R3, [R3] @ load value of shift amt
        MOV R0, #0b111 @ mask to clear 3 bits
        LSL R0, R3 @ shift into position
        BIC R1, R0 @ clear the three bits
        MOV R0, #1 @ 1 bit to shift into pos
        LSL R0, R3 @ shift by amount from table
        ORR R1, R0 @ set the bit
        STR R1, [R8, R2] @ save it to reg to do work
.endm

.macro GPIOTurnOn pin, value
        MOV R2, R8 @ address of gpio regs
        ADD R2, #setregoffset @ off to set reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8 @ add offset for shift amt
        LDR R3, [R3] @ load shift from table
        LSL R0, R3 @ do the shift
        STR R0, [R2] @ write to the register
	nanoSleep timespecnano150
.endm

.macro GPIOTurnOff pin, value
	nanoSleep timespecnano150
        MOV R2, R8 @ address of gpio regs
        ADD R2, #clrregoffset @ off set of clr reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8
        LDR R3, [R3]
        LSL R0, R3
        STR R0, [R2]
.endm

@Macro para realizar a inicialização do display LCD, juntamente com as functions set
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

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOn pin12 @On no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOn pin12 @On no DB4
	GPIOTurnOff pin1 @Off no Enable

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos
	
	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas 

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos
	
	@Parte da inicialização em que realiza um off no display
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOn pin21 @On no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos

	@Parte da inicialização em que realiza um clear no display
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOn pin12 @On no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos
	
	@Parte da inicialização em que realiza o entry mode set no display
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOn pin20 @On no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos

	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas
.endm

@Macro que chama a saída dos pinos do display
.macro initPins
	GPIODirectionOut pin1 @Enable
	GPIODirectionOut pin12 @DB4
	GPIODirectionOut pin16 @DB5
	GPIODirectionOut pin20 @DB6
	GPIODirectionOut pin21 @DB7
	GPIODirectionOut pin25 @rs
	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas 
.endm

@Macro que realiza o entry mode set do display
.macro entryModeSet
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOn pin21 @On no DB7
	GPIOTurnOn pin20 @On no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOn pin20 @On no DB6
	GPIOTurnOn pin16 @On no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos

	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas
.endm

@Macro para realizar um clear no LCD
.macro clearLCD
	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOff pin12 @Off no DB4
	GPIOTurnOff pin1

	GPIOTurnOff pin1 @Off no Enable
	GPIOTurnOff pin25 @Off no rs
	GPIOTurnOn pin1 @On no Enable
	GPIOTurnOff pin21 @Off no DB7
	GPIOTurnOff pin20 @Off no DB6
	GPIOTurnOff pin16 @Off no DB5
	GPIOTurnOn pin12 @On no DB4
	GPIOTurnOff pin1 @Off no Enable
	nanoSleep timespecnano150 @Temporização de 15 milisegundos
.endm

.macro writeDezena
	writeDecimal 1, 0, 0, 1
	write9to0
	clearLCD

        writeDecimal 1, 0, 0, 0
	write9to0   
        clearLCD

        writeDecimal 0, 1, 1, 1

        writeDecimal 0, 1, 1, 0

        writeDecimal 0, 1, 0, 1

        writeDecimal 0, 1, 0, 0

        writeDecimal 0, 0, 1, 1

        writeDecimal 0, 0, 1, 0

        writeDecimal 0, 0, 0, 1

        writeDecimal 0, 0, 0, 0
.endm

.macro write9to0
	writeDecimal 1, 0, 0, 1

	writeDecimal 1, 0, 0, 0

	writeDecimal 0, 1, 1, 1

	writeDecimal 0, 1, 1, 0

	writeDecimal 0, 1, 0, 1

	writeDecimal 0, 1, 0, 0

	writeDecimal 0, 0, 1, 1

	writeDecimal 0, 0, 1, 0

	writeDecimal 0, 0, 0, 1

	writeDecimal 0, 0, 0, 0
.endm

.macro writeNumber
	GPIOTurnOff pin1
	GPIOTurnOn pin25
	GPIOTurnOn pin1
	GPIOTurnOff pin21
	GPIOTurnOff pin20
	GPIOTurnOn pin16
	GPIOTurnOn pin12
	GPIOTurnOff pin1
.endm

.macro writeDecimal d7, d6, d5, d4
	writeNumber

	GPIOTurnOff pin1
	GPIOTurnOn pin25
	GPIOTurnOn pin1
	GPIOTurnOnOff pin21, #\d7
	GPIOTurnOnOff pin20, #\d6
	GPIOTurnOnOff pin16, #\d5
	GPIOTurnOnOff pin12, #\d4
	GPIOTurnOff pin1
	nanoSleep timespecnano150
	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas
.endm

.macro GPIOTurnOnOff pin, value
	MOV R0, #clrregoffset 
        MOV R2, #12
        MOV R1, \value
        MUL R5, R2, R1
        SUB R0, R0, R5
        MOV R2, R8
        ADD R2, R2, R0
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8 @ add offset for shift amt
        LDR R3, [R3] @ load shift from table
        LSL R0, R3 @ do the shift
        STR R0, [R2] @ write to the register
	nanoSleep timespecnano150
.endm

.macro startCounter
	
.endm

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


	GPIODirectionOut pin6
	GPIOTurnOn pin6
	nanoSleep timespecnano150
	GPIOTurnOff pin6
	GPIODirectionOut pin13
	GPIOTurnOn pin13
	nanoSleep timespecnano150
	GPIOTurnOff pin13

	initPins @chamando a macro para inicializar os pinos do display
	initializeDisplay @chamando a macro para inicializar o display
	entryModeSet @chamando a macro para realizar o entry mode set

	clearLCD @chamando a macro para limpar o display
	write9to0
	.ltorg @Quando se tem um programa muito grande é necessário utilizar essa função para que o processador não tente executar funções indevidas

	GPIOTurnOn pin13
	nanoSleep timespecnano150
	GPIOTurnOff pin13
	clearLCD

	writeDezena
	clearLCD

_end:   MOV R0, #0
        MOV R7, #1
        SVC 0
	@FINALIZANDO O DECREMENTADOR

.data
second: .word 1 			@definindo 1 segundo no nanosleep 
timenano: .word 0000000000 		@definindo o milisegundos para o segundo passar no nanosleep
timespecsec: .word 0 			@definição do nano sleep 0s permitindo os milissegundos
timespecnano20: .word 20000000 		@chamada de nanoSleep
timespecnano5: .word 5000000 		@valor em milisegundos para lcd
timespecnano150: .word 150000 		@valor em milisegundos para LCD
timespecnano1s: .word 999999999 	@valor para delay de contador
fileName: .asciz "/dev/mem"		@Endereço do do dev/mem.
gpioaddr: .word 0x20200			@Endereço base.


@Valores referentes ao GPSEL que controla os pinos, sendo o endereço inicial e o primeiro dos três bits de cada pino.
pin6:	.word 0
       	.word 18
       	.word 6
pin13: 	.word 4
	.word 9
	.word 13
pin25:	.word 8    	 @RS
	.word 15
	.word 25
pin1:	.word 0    	@E
	.word 3
	.word 1
pin12:	.word 4		@D4
	.word 6
	.word 12
pin16:	.word 4    	@D5
	.word 18
	.word 16
pin20:	.word 8    	@D6
	.word 0
	.word 20
pin21:	.word 8  	@D7
	.word 3
	.word 21
pin5: 	.word 0  	@PB1
	.word 15
	.word 5
pin19:	.word 4  	@PB2
	.word 27
	.word 19
pin26:	.word 8 	@PB3
	.word 18
	.word 26
        .word 0300000000
