#include "meuAlocador.h"

int main()
{
  void *a, *b;
  iniciaAlocador();

  a = alocaMem(4080);
  liberaMem(a);

  b = alocaMem(8176);
  imprimeMapa();
  
  liberaMem(b);
  imprimeMapa();

  finalizaAlocador();
  return 0;
}
