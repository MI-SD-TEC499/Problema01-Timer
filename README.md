# Problema 01 - Timer
# Integrantes: Daniel Costa, Diego Silva e Thiago Menezes

# 1 - Introdução
Com o avanço da tecnologia, inclusive a de construção de transistores, tem sido possibilitado cada vez mais a construção de computadores com menor tamanho, melhor desempenho, incluindo energético, e menor custo. Sistemas embarcados em microcontroladores são utilizados para diversas tarefas de automação e na chamada _Internet of Things_ (IoT).

O problema apresentado a seguir consistiu no desenvolvimento de um temporizador em um microcontrolador Raspberry Pi Zero, utilizando uma linguagem de montagem com arquitetura ARM. O temporizador deve contar com funções básicas de controle do tempo, sendo possível parar e iniciar a temporização, assim como reiniciá-la a partir do tempo inicial.

# 2 - Desenvolvimento
**2.1 - Nanosleep:**

![image](https://user-images.githubusercontent.com/111393549/192642333-7be43a3a-f703-4d4c-9fa9-4c0f6ae628f9.png)

O macro em questão é utilizado para fazer o sistema “dormir” durante um tempo pré-determinado sempre que existir a necessidade de esperar um intervalo específico entre instruções, são passados dois argumentos para o macro : "timespecsec" que é um valor fixo, e "time" que define quanto tempo a execução fica em espera, depois é enviado ao R7 o vallor da syscall(162), que é executada em seguida.
É vital para o funcionamento do display, que precisa de delays específicos entre os conjuntos de instruções.

**2.2 - Usando um pino como output:**

![image](https://user-images.githubusercontent.com/111393549/192646024-306637d8-7783-4c63-8402-9833781490a1.png)

Quando um pino é usado, devemos informar se ele vai servir como entrada ou saída, na imagem o pino é setado como output : Primeiramente informamos o endereço base do pino(com base no FSEL referente no datasheet), depois passamos a posição do primeiro bit reservado para o pino(cada FSEL é responsável por 10 pinos com 3 bits para cada), e então fazemos um Shift para a posição correta(com base no valor passado), e salvamos o resultado em um registrador.

**2.3 - Ativando um pino:**

![image](https://user-images.githubusercontent.com/111393549/192645909-fc9caecf-305b-4c4a-9049-be2b6688e4a0.png)

Após um pino ter sua função definida, ele vai ser ligado de acordo com a necessidade do projeto, seguindo a lógica da macro “GPIODirectionOut”,  começamos passando o endereço armazenado no R8, depois passamos o offset do registrador set1(a diferença entre ligar e desligar o pino é basicamente o offset enviado, set para ligar, e clear para desligar).

**2.4 - Abrindo arquivos e mapeando a memória:**

![image](https://user-images.githubusercontent.com/111393549/192645367-82ef86f6-05c9-41ea-ac0e-046159c400fb.png)

Assim que o programa inicia realizamos o mapeamento de memória, onde recebemos um endereço virtual(com base no endereço físico) para os componentes que vão ser utilizados : A princípio acessamos o diretório “dev/mem”  depois, utilizando a syscall “sys_open”, os valores carregados nos registradores servem para encontrar o arquivo correto, depois o “SVC 0” executa a syscall.
Armazenamos então o endereço base no R5, e utilizamos algumas constantes como parâmetros, “prot_read” e “prot_write” que permitem a leitura e escrita, “map_shared” garante que outros processos saibam que aquela região está sendo mapeada, e "pagelen" é referente ao tamanho separado para a memória, por fim passamos o valor da syscall “sys_map” para o R7, e iniciamos o mapeamento chamando novamente o “SVC 0”.

Com a memória mapeada, podemos começar o processo de contagem:
1. Inicializando os pinos (setando como output):
![image](https://user-images.githubusercontent.com/111393549/192648400-889c5f0a-a32f-4e84-950b-e3150636cef7.png)


2. Inicializando o display:




**2.x - GPIO pins:**

![image](https://user-images.githubusercontent.com/111393549/192644893-8dda5069-05aa-4af8-bc33-900e7e52dc03.png)

Nós acessamos os periféricos da placa através da GPIO(General purpose input output), mas para que os pinos utilizados funcionem, é necessário valores especificos, usando o pin25(RS) como exemplo , associamos a "pin25" os valores "8" para utilizarmos o GPSEL2 que controla os pinos 20-29, depois enviamos
um "15", que representa o primeiro dos três bits do pin25 (são 32 bits para o GPSEL2, sendo três para cada pino controlado).



