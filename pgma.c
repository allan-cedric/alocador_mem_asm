#include <stdio.h>
#include "meuAlocador.h"

int main()
{
  void *a, *b, *c;
  iniciaAlocador();

  a = alocaMem(100);
  b = alocaMem(20);
  c = alocaMem(4);
  printf("mapa 1:\n");
  imprimeMapa();

  liberaMem(a);
  liberaMem(b);
  liberaMem(c);
  printf("mapa 2:\n");
  imprimeMapa();

  a = alocaMem(5);
  printf("mapa 3:\n");
  imprimeMapa();

  b = alocaMem(3);
  printf("mapa 4:\n");
  imprimeMapa();

  liberaMem(a);
  liberaMem(b);
  printf("mapa 5:\n");
  imprimeMapa();

  finalizaAlocador();
  return 0;
}
