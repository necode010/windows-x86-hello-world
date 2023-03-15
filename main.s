.data
    test_string: .ascii "test\n"
    get_std_handle: .ascii "GetStdHandle"
    get_std_handle_len: .quad 12
    get_std_handle_address: .quad 0
    write_console: .ascii "WriteConsole"
    write_console_len: .quad 12
    write_console_address: .quad 0
    hello_world: .ascii "Hello world!"
    hello_world_len: .quad 12

.text
.globl _start

_start:
    movq %gs:0x60, %rax; // gs:0x60 = PEB
    movq 0x18(%rax), %rax; // PEB->Ldr
    movq 0x10(%rax), %rcx; // InLoadOrderModuleList.Flink
    
module_loop:
    movq 0x0(%rcx), %rcx; // InLoadOrderLinks.Flink
    movq 0x60(%rcx), %rdx; // BaseDllName
    cmpb $0x33, 0xC(%rdx); // BaseDllName.Buffer[0] == '3'
    jnz module_loop;
    
    movq 0x30(%rcx), %rbx; // DllBase
    movq 0x3c(%rbx), %rcx; // e_lfanew
    leal (%ecx), %edx;
    leaq (%rbx, %rdx), %rax;
    
    movq 0x88(%rax), %rax; // NT->OptionalHeader.DataDirectory[0]
    leal (%eax), %edx;
    leaq (%rbx, %rdx), %rdx;
    
    movq 0x1C(%rdx), %rsi; // AddressOfFunctions
    movl %esi, %esi;
    leaq (%rbx, %rsi), %r8;
    
    movq 0x20(%rdx), %rsi; // AddressOfNames
    movl %esi, %esi;
    leaq (%rbx, %rsi), %r9;
    
    movq 0x24(%rdx), %rsi; // AddressOfNameOrdinals
    movl %esi, %esi;
    leaq (%rbx, %rsi), %r10;
    
    leaq get_std_handle(%rip), %r11;
    movq get_std_handle_len(%rip), %r12;
    xor %rdi, %rdi;
    call get_export;
    movq %rax, get_std_handle_address(%rip);
    
    leaq write_console(%rip), %r11;
    movq write_console_len(%rip), %r12;
    xor %rdi, %rdi;
    call get_export;
    movq %rax, write_console_address(%rip);
    
    xorq %rbx, %rbx;
    movl $0x0FFFFFFF5, %ecx; // nStdHandle
    movq get_std_handle_address(%rip), %rax;
    callq *%rax;
    movl %eax, %ebx;
    
    movl %ebx, %ecx; // hConsoleOutput
    leaq hello_world(%rip), %rdx; // lpBuffer
    movq hello_world_len(%rip), %r8; // nNumberOfCharsToWrite
    xorq %r9, %r9; // lpNumberOfCharsWritten
    movq write_console_address(%rip), %rax;
    callq *%rax;
    
    ret;
    
memcmp:
    xorl %eax, %eax;
    repe cmpsb;
    setne %al;
    ret;
    
get_export:
    movq (%r9, %rdi, 4), %rcx;
    movl %ecx, %ecx;
    leaq (%rbx, %rcx), %rdx;
    
    pushq %rsi;
    pushq %rdi;
    pushq %rbx;
    
    movq %rdx, %rdi;
    movq %r11, %rsi;
    movq %r12, %rcx;
    call memcmp;
    
    popq %rbx;
    popq %rdi;
    popq %rsi;
    
    inc %rdi;
    
    test %rax, %rax;
    jnz get_export;
    
    dec %rdi;
    xor %rax, %rax;
    movq (%r10, %rdi, 2), %rcx;
    movw %cx, %ax;
    
    movq (%r8, %rax, 4), %rcx;
    movl %ecx, %ecx;
    leaq (%rbx, %rcx), %rdx;
    
    movq %rdx, %rax;
    ret;
.data