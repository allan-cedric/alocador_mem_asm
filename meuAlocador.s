.section .data
    HEAP_BOTTOM:    .quad   0       # Altura inicial da heap
    HEAP_POINTER:   .quad   0       # Altura efetiva da heap
    HEAP_TOP:       .quad   0       # Altura máxima da heap
    LINE_FEED:      .string "\n"

# ----- Constantes -----
.equ    BRK,            12      # Syscall brk ID      
.equ    GER_FLAG,       35      # ASCII Char: '#'
.equ    DISP_FLAG,      46      # ASCII Char: '.'   
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

    movq    $LINE_FEED, %rdi    
    call    printf              # Buffer de impressão alocado

    movq    $BRK, %rax          # Syscall brk
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

    movq    $BRK, %rax          # Syscall brk
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
    movq    $0, %rax                # Endereço do melhor bloco para alocar
    while:
        cmpq    %r13, %r12          # Se %r12 >= HEAP_POINTER, pula pra fimWhile
        jge     fimWhile

        movq    -16(%r12), %r8      # %r8 := Estado do bloco atual
        movq    -8(%r12), %r9       # %r9 := Tamanho do bloco atual

        cmpq    $1, %r8             # Se bloco está ocupado, pula pra next
        je      next

        cmpq    %r14, %r9           # Se sizeof(bloco atual) < sizeof(bloco pedido), pula pra next
        jl      next

        cmpq    $0, %rax            # Se for o primeiro bloco válido, realiza FirstFit direto
        je      fit

        cmpq    %rbx, %r9           # Se sizeof(bloco atual) >= sizeof(bloco candidato), pula pra next
        jge     next
    
        fit:
            movq    %r9, %rbx       # %rbx := Tamanho do bloco candidato
            movq    %r12, %rax      # %rax := Endereço do novo bloco candidato

        next:
            addq    %r9, %r12       # %r12 := %r12 + sizeof(bloco atual) 
            addq    $16, %r12       # %r12 := %r12 + sizeof(header)
            jmp     while
    
    fimWhile:
        cmpq    $0, %rax            # Se %rax é 0, pula pra criaBloco
        je      criaBloco
        movq    $1, -16(%rax)       # Bloco está ocupado agora
        jmp     fimAlocaMem

    criaBloco:
        addq    %r14, %r12              # %r12 := (HEAP_POINTER + sizeof(header)) + sizeof(bloco pedido)
        
        cmpq    HEAP_TOP, %r12          # Se %r12 > HEAP_TOP, pula pra aloca
        jg      aloca

        movq    %r12, HEAP_POINTER      # Atualiza HEAP_POINTER
        subq    %r14, %r12              
        movq    %r12, %rax              # Endereço do novo bloco
        
        movq    $1, -16(%rax)           # Bloco está ocupado agora
        movq    %r14, -8(%rax)          # Tamanho do novo bloco
        jmp     fimAlocaMem

    aloca:
        addq    $16, %rdi           # %rdi := sizeof(header + bloco pedido)
        movq    $4096, %r10         # %r10 := Página(s) a ser alocada

        while1:
            cmpq    %r10, %rdi          # Se sizeof(bloco) <= sizeof(página), pula pra fimWhile1
            jle     fimWhile1
            addq    $4096, %r10
            jmp     while1

        fimWhile1:
            movq    $BRK, %rax          # Syscall brk
            addq    %r15, %r10          # %r10 := %r10 + HEAP_TOP
            movq    %r10, %rdi
            syscall                     # brk(%r10)
            
            movq    %rax, HEAP_TOP      # HEAP_TOP := brk(%r10)     
            movq    %r13, %rax          # %rax := HEAP_POINTER (Anterior)
            
            addq    $16, %r13           # %r13 := %r13 + sizeof(header)
            addq    %r14, %r13          # %r13 := %r13 + sizeof(bloco pedido)
            movq    %r13, HEAP_POINTER  # Atualiza HEAP_POINTER         

            movq    $1, (%rax)          # Bloco está ocupado agora
            movq    %r14, 8(%rax)       # Tamanho do bloco
            addq    $16, %rax           # Endereço do novo bloco

    fimAlocaMem:
        popq   %r15
        popq   %r14
        popq   %r13
        popq   %r12
        popq   %rbp                     # Restaura %rbp e desempilha %rbp anterior   
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
        cmpq    HEAP_POINTER, %r12  # Se %r12 == HEAP_POINTER, pula pra fimImprimeMapa
        je      fimImprimeMapa

        # Avaliando novo bloco
        movq    $0, %r15
        for:
            cmpq    $16, %r15       # Se %r15 >= 16, pula pra fimFor
            jge     fimFor
            movq    $GER_FLAG, %rdi
            call    putchar         # putchar('#')
            addq    $1, %r15        # %r15 := %r15 + 1
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
                cmpq    -8(%r12), %r15      # Se %r15 >= sizeof(bloco), pula pra nextBloco
                jge     nextBloco
                movq    %r13, %rdi
                call    putchar             # putchar(%r13)
                addq    $1, %r15            # %r15 := %r15 + 1
                jmp     while2
            
        nextBloco:
            movq    -8(%r12), %rsi          # %rsi := sizeof(bloco)
            addq    %rsi, %r12              # %r12 := %r12 + sizeof(bloco)
            jmp     alocado

    disponivel: # Área da heap alocada mas não usada (opcional)
        cmpq    HEAP_TOP, %r12           
        jge     fimImprimeMapa
        movq    $DISP_FLAG, %rdi
        call    putchar             # putchar('*')
        addq    $1, %r12
        jmp     disponivel

    fimImprimeMapa:
        movq    $10, %rdi
        call    putchar             # putchar('\n')
        movq    $10, %rdi           
        call    putchar             # putchar('\n')
        
        popq    %r15
        popq    %r13
        popq    %r12
        popq    %rbp                # Restaura %rbp e desempilha %rbp anterior   
        ret
