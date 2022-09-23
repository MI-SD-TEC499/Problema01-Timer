#execução dos executaveis
all: sudo ./timer

#criação dos executaveis
timer: timer.o 
	ld -o $@ $+

#criação dos objetos
timer.o: timer.s
	as -o $@ $<
