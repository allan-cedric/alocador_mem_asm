.section .data
    HEAP_BOTTOM:    .quad   0       # Altura inicial da heap
    HEAP_POINTER:   .quad   0       # Altura efetiva da heap
    HEAP_TOP:       .quad   0       # Altura máxima da heap
    EMPTY_STR:      .string ""

# ----- Constantes -----      
.equ    GER_FLAG,       35      # ASCII Char: '#'
.equ    DIPS_FLAG,      42      # ASCII Char: '*'   
.equ    OCUPADO_FLAG,   43      # ASCII Char: '+'
.equ    LIVRE_FLAG,     45      # ASCII Char: '-'


.section .text

# ----- Símbolos globais -----
.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
.globl liberaMem
.globl imprimeMapa

# ----- iniciaAlocador -----
iniciaAlocador:
    pushq   %rbp                # Empilha %rbp
    movq    %rsp, %rbp          # %rbp aponta para o %rbp anterior

    movq    $EMPTY_STR, %rdi    
    call    printf              # Buffer de impressão alocado

    movq    $12, %rax           # Syscall brk
    movq    $0, %rdi
    syscall                     # brk(0)

    movq    %rax, HEAP_BOTTOM   # HEAP_BOTTOM := brk(0)
    movq    %rax, HEAP_POINTER  # HEAP_POINTER := brk(0)
    movq    %rax, HEAP_TOP      # HEAP_TOP := brk(0)

    popq    %rbp                # Restaura %rbp e desempilha %rbp anterior   
    ret

# ----- finalizaAlocador -----
finalizaAlocador:
    pushq   %rbp                # Empilha %rbp
    movq    %rsp, %rbp          # %rbp aponta para o %rbp anterior

    movq    $12, %rax           # Syscall brk
    movq    HEAP_BOTTOM, %rdi
    syscall                     # brk(HEAP_BOTTOM)

    popq    %rbp                # Restaura %rbp e desempilha %rbp anterior   
    ret

# ----- alocaMem -----
alocaMem:
    pushq   %rbp                    # Empilha %rbp
    movq    %rsp, %rbp              # %rbp aponta para o %rbp anterior

    # Salva %r12, %r13, %r14 e %r15 na pilha
    pushq   %r12                
    pushq   %r13                
    pushq   %r14
    pushq   %r15

    movq    HEAP_BOTTOM, %r12       # %r12 := HEAP_BOTTOM           
    movq    HEAP_POINTER, %r13      # %r13 := HEAP_POINTER
    movq    %rdi, %r14              # %r14 := (Bloco pedido)
    movq    HEAP_TOP, %r15          # %r15 := HEAP_TOP

    addq    $16, %r12               # Endereço do possível primeiro bloco
    while:
        cmpq    %r13, %r12          # Estourou HEAP_POINTER ?
        jge     criaBloco

        movq    -16(%r12), %r8      # Estado do bloco atual
        movq    -8(%r12), %r9       # Tamanho do bloco atual

        cmpq    $1, %r8             # Bloco está ocupado ?
        je      next

        cmpq    %r14, %r9           # sizeof(bloco atual) < sizeof(bloco pedido) ?
        jl      next

        movq    %r12, %rax          # Endereço do novo bloco
        movq    $1, -16(%rax)       # Bloco está ocupado agora
        jmp     fimAlocaMem

        next:
            addq    %r9, %r12       # %r12 := %r12 + sizeof(bloco atual) 
            addq    $16, %r12       # %r12 := %r12 + sizeof(header)
            jmp     while

criaBloco:
    addq    %r14, %r12              # %r12 := (HEAP_POINTER + sizeof(header)) + sizeof(bloco pedido)
    
    cmpq    HEAP_TOP, %r12          # %r12 > HEAP_TOP ?
    jg      aloca

    movq    %r12, HEAP_POINTER      # Atualiza HEAP_POINTER
    subq    %r14, %r12              
    movq    %r12, %rax              # Endereço do novo bloco (retorno)
    
    movq    $1, -16(%rax)           # Bloco está ocupado agora
    movq    %r14, -8(%rax)          # Tamanho do novo bloco
    jmp     fimAlocaMem


aloca:
    addq    $16, %rdi           # %rdi := sizeof(header + bloco pedido)
    movq    $4096, %r10         # Página a ser alocada

    while1:
        cmpq    %r10, %rdi          # %rdi <= %r10 ?
        jle     fimWhile1
        addq    $4096, %r10
        jmp     while1

    fimWhile1:
        movq    $12, %rax           # Syscall brk
        addq    %r15, %r10          # %r10 := tamanho da página + HEAP_TOP
        movq    %r10, %rdi
        syscall                     # brk(tamanho da página + HEAP_TOP)
        
        movq    %rax, HEAP_TOP      # HEAP_TOP := brk(tamanho da página + HEAP_TOP)     
        movq    %r13, %rax          # %rax := $HEAP_POINTER (Anterior)
        
        addq    $16, %r13
        addq    %r14, %r13
        movq    %r13, HEAP_POINTER           

        movq    $1, (%rax)          # Bloco está ocupado agora
        movq    %r14, 8(%rax)       # Tamanho do bloco
        addq    $16, %rax           # Endereço do novo bloco

fimAlocaMem:
    popq   %r15
    popq   %r14
    popq   %r13
    popq   %r12
    popq   %rbp                # Restaura %rbp e desempilha %rbp anterior   
    ret

# ----- liberaMem -----
liberaMem:
    pushq   %rbp                # Empilha %rbp
    movq    %rsp, %rbp          # %rbp aponta para o %rbp anterior

    movq    $0, -16(%rdi)       # (%rdi - 16)* := 0 (Bloco está livre)

    popq    %rbp                # Restaura %rbp e desempilha %rbp anterior   
    ret

# ----- imprimeMapa -----
imprimeMapa:
    pushq   %rbp                # Empilha %rbp
    movq    %rsp, %rbp          # %rbp aponta para o %rbp anterior

    # Salva %r12, %r13 e %r15 na pilha
    pushq   %r12        
    pushq   %r13
    pushq   %r15

    movq    HEAP_BOTTOM, %r12   # %r12 := HEAP_BOTTOM

alocado:
    cmpq    HEAP_POINTER, %r12  # %r12 == HEAP_POINTER ?
    je      disponivel

    # Avaliando novo bloco
    movq    $0, %r15
    for:
        cmpq    $16, %r15
        jge     fimFor

        movq    $GER_FLAG, %rdi
        call    putchar
        addq    $1, %r15

        jmp     for


    fimFor:
        addq    $16, %r12               # Endereço do bloco atual 

        cmpq    $1, -16(%r12)           # Bloco está ocupado ?
        je      else
        movq    $LIVRE_FLAG, %r13       # Char de bloco livre
        jmp     endIf
        else:
            movq    $OCUPADO_FLAG, %r13 # Char de bloco ocupado
        endIf:
            movq    $0, %r15

        while2:
            cmpq    -8(%r12), %r15      # %r15 >= sizeof(bloco) ?
            jge      nextBloco
            movq    %r13, %rdi
            call    putchar             # putchar(%r13)
            addq    $1, %r15
            jmp     while2
        
    nextBloco:
        movq    -8(%r12), %rsi          # %rsi := sizeof(bloco)
        addq    %rsi, %r12              # %r12 := %r12 + sizeof(bloco)
        jmp     alocado

disponivel: # Área da heap alocada mas sem blocos
    cmpq    HEAP_TOP, %r12           
    jge     fimImprimeMapa

    movq    $DIPS_FLAG, %rdi
    call    putchar

    addq    $1, %r12
    jmp     disponivel

fimImprimeMapa:
    # Imprime 2 '\n'
    movq    $10, %rdi
    call    putchar
    movq    $10, %rdi
    call    putchar
    
    popq    %r15
    popq    %r13
    popq    %r12
    popq    %rbp                # Restaura %rbp e desempilha %rbp anterior   
    ret
