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

![image](https://user-images.githubusercontent.com/111393549/192642333-7be43a3a-f703-4d4c-9fa9-4c0f6ae628f9.png)

O macro em questão é utilizado para fazer o sistema “dormir” durante um tempo pré-determinado sempre que existir a necessidade de esperar um intervalo específico entre instruções, são passados dois argumentos para o macro : 
- `timespecsec` que é um valor fixo.
- `time` que define quanto tempo a execução fica em espera.

Depois é enviado ao R7 o valor da syscall(162), que é executada em seguida.
O `nanosleep` é vital para o funcionamento do display, que precisa de delays específicos entre os conjuntos de instruções.

**3.2 - Usando um pino como output:**

![image](https://user-images.githubusercontent.com/111393549/192646024-306637d8-7783-4c63-8402-9833781490a1.png)

Quando um pino é usado, devemos informar se ele vai servir como entrada ou saída, na imagem o pino é setado como output :
- Informamos o endereço base do pino(com base no FSEL referente no datasheet)
- Passamos a posição do primeiro bit reservado para o pino(cada FSEL é responsável por 10 pinos com 3 bits para cada),
- Fazemos um Shift para a posição correta(com base no valor passado), e salvamos o resultado em um registrador.

**3.3 - Ativando um pino:**

![image](https://user-images.githubusercontent.com/111393549/192645909-fc9caecf-305b-4c4a-9049-be2b6688e4a0.png)

Após um pino ter sua função definida, ele vai ser ligado de acordo com a necessidade do projeto, seguindo a lógica da macro `GPIODirectionOut`,  começamos passando o endereço armazenado no R8, depois passamos o offset do registrador set1(a diferença entre ligar e desligar o pino é basicamente o offset enviado, set para ligar, e clear para desligar).

**3.4 - Abrindo arquivos e mapeando a memória:**

![image](https://user-images.githubusercontent.com/111393549/192645367-82ef86f6-05c9-41ea-ac0e-046159c400fb.png)

Assim que o programa inicia realizamos o mapeamento de memória, onde recebemos um endereço virtual(com base no endereço físico) para os componentes que vão ser utilizados : 
1. A princípio acessamos o diretório “dev/mem” utilizando a syscall `sys_open` (os valores carregados nos registradores servem como parâmetros para encontrar o endereço correto, depois o `SVC 0` executa a syscall.
2. Armazenamos então o endereço base no R5, e utilizamos algumas constantes como parâmetros, `prot_read` e `prot_write` que permitem a leitura e escrita de arquivos, `map_shared` garante que outros processos saibam que aquela região está sendo mapeada, e `pagelen` é referente ao tamanho separado para a memória, por fim passamos o valor da syscall `sys_map` para o R7, e iniciamos o mapeamento chamando novamente o `SVC 0`.

Com a memória mapeada, começamos a preparação do display:
1. Inicializando os pinos (setando como output):
![image](https://user-images.githubusercontent.com/111393549/192648400-889c5f0a-a32f-4e84-950b-e3150636cef7.png)



2. Inicializando o display:
Antes de começar a escrever no display, devemos inicializa-lo através de instruções.
- O método se resume em enviar um instruction set, e esperar um tempo especifico:

![image](https://user-images.githubusercontent.com/111393549/192655249-ec1335f6-a5ab-4932-a851-451985cc9ea0.png)

No código acima enviamos um "1" para o `DB4` e para o `DB5`, depois é estabelecido um delay de 5 nanosegundos.
- Em cada grupo de instruções, definimos quais data bits do display recebem 0 ou 1, isso é feito seguindo a ordem definida no datasheet.
- O processo se repete algumas vezes, mas com valores diferentes em cada `Data Bit`.

**3.5 - Iniciando a contagem:**
Depois que o display for inicializado começamos a contagem de 9 a 0, para isso utilizamos o macro `write9to0` : 

![image](https://user-images.githubusercontent.com/111393549/192651194-2a7c4ab5-515b-40d2-8815-1d681d8bc9c0.png)

A escrita de dados no display é feita através de um grupo de instruções onde informamos o valor passado a cada data bit(similar a inicialização do display), são dois instruction sets seguindo a ordem informada no datasheet do display, para escrever o numero 5 por exemplo :
1. Enviamos um 0011(`DB7,DB6,DB5,DB4` respectivamente) para os upper bits
2. 0101 para os lower bits.
3. Por fim um pulso no enable. 

![image](https://user-images.githubusercontent.com/111393549/192658064-afc0256b-25c4-46d8-8e00-fac44e20342b.png)

A imagem acima representa o envio dos valores aos lower bits.


**3.6 - GPIO pins:**

![image](https://user-images.githubusercontent.com/111393549/192644893-8dda5069-05aa-4af8-bc33-900e7e52dc03.png)

Nós acessamos os periféricos da placa através da GPIO(General purpose input output), mas para que os pinos utilizados funcionem, é necessário valores especificos, usando o `pin25`(RS) como exemplo , associamos ao `pin25` os valores "8" para utilizarmos o GPSEL2 que controla os pinos 20-29, depois enviamos
um "15", que representa o primeiro dos três bits do pin25 (são 32 bits para o GPSEL2, sendo três para cada pino controlado).

**3.7 - Tipos de instruções utilizadas:**

**Aritmética:**
- `ADD`
- `SUB`

**Manipulação/movimentação:**
- `LSL`
- `MOV`
- `STR`
- `LDR`

**Lógica:**
- `ORR`
- `BIC`

# 4 - Referências
![Raspberry Pi Assembly Language Programming](https://link.springer.com/book/10.1007/978-1-4842-5287-1)

![Manual Display HD44780U (LCD-16x2)](https://www.sparkfun.com/datasheets/LCD/HD44780.pdf)
