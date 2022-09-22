# Problema01-Timer

# 1 - Introdução


# 2 - Desenvolvimento
![SleepImg](https://user-images.githubusercontent.com/111393549/191847559-c0fcf7c3-8f04-4661-8892-48458bcd729f.png)

O macro em questão é utilizado para fazer o sistema “dormir” durante um tempo pré-determinado, sempre que existe a necessidade de esperar um tempo específico entre instruções, é vital para o funcionamento do display onde é necessario delays entre os conjuntos de instruções.

![dirOutimg](https://user-images.githubusercontent.com/111393549/191847939-efd42a4c-b207-48c5-8492-f56c376e2339.png)

Quando um pino é usado, devemos informar se ele vai servir como entrada ou saída, na imagem o pino é setado como output : Primeiramente informamos o endereço base do pino(com base no FSEL referente no datasheet), depois passamos a posição do primeiro bit reservado para o pino(cada FSEL é responsável por 10 pinos com 3 bits para cada), e então fazemos um Shift para a posição correta(com base no valor passado), e salvamos o resultado em um registrador.

![turnOnimg](https://user-images.githubusercontent.com/111393549/191848281-af6dafb3-2635-4fd2-8631-39651bdef4ec.png)

Após um pino ter sua função definida, ele vai ser ligado de acordo com a necessidade do projeto, seguindo a lógica da macro “GPIODirectionOut”,  começamos passando o endereço armazenado no R8, depois passamos o offset do registrador set1(a diferença entre ligar e desligar o pino é basicamente o offset enviado, set para ligar, e clear para desligar).

![mappingImg](https://user-images.githubusercontent.com/111393549/191851132-b12fac75-b10c-42de-ac52-c81f53d18e7f.png)

Assim que o programa inicia fazemos o mapeamento de memória, onde recebemos um endereço virtual(com base no endereço físico) para os componentes que vão ser utilizados : A princípio acessamos o diretório “dev/mem” , utilizando a syscall “sys_open”, os valores carregados nos registradores servem para encontrar o arquivo correto, depois o “SVC 0” executa a syscall.
Depois armazenamos o endereço base no R5, e utilizamos algumas constantes como parâmetros, “prot_read” e “prot_write” que permitem a leitura e  escrita, “map_shared” garante que outros processos saibam que aquela região está sendo mapeada, e "pagelen" é referente ao tamanho separado para a memória, por fim passamos o valor da syscall “sys_map” para o R7, e iniciamos o mapeamento chamando novamente o “SVC 0”.



