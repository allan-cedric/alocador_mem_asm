## Trabalho 1 da disciplina de Software Básico (CI1064) - UFPR

### Autores
*   Allan Cedric G. B. Alves da Silva - GRR20190351
*   Gabriel N. Hishida do Nascimento - GRR20190361

### Sobre o projeto
*   Implementação de um alocador de memória na linguagem assembly `x86_64`

### API

*   `iniciaAlocador`: Inicializa a estrutura de dados de gerenciamento da heap.
*   `finalizaAlocador`: Restaura a variável `brk`, basicamente restaura para área inicial da heap.
*   `alocaMem`: Aloca memória na heap, ajustando se necessário a variável `brk` sob demanda em páginas múltiplas de 4096 bytes. O algoritmo de alocação utilizado foi o **Best Fit**.
*   `liberaMem`: Libera memória da heap, basicamente torna um bloco da heap livre através de uma flag gerencial.
*   `imprimeMapa`: Imprime o mapa de memória da heap, os bytes gerenciais dos blocos são impressos com o caractere `#`, os bytes de dados com `+` se ocupados e `-` se livres. **Ademais, os bytes alocados mas não utilizados são denotados por `.` (Opcional)**.

### Executando o projeto

*   Compilação: `make`
*   Execução: `./pgma`

