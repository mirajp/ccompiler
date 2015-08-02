.data
.LC0:
        .string "hello: %d\n"
.text
.global main
main:
        pushl   %ebp
        movl    %esp, %ebp
        
        ; ARGBEGIN 2
        subl    $12, %esp
        
        
        movl    $.LC0, %eax
        movl    %eax, 0(%esp)

        movl    $10, %eax
        movl    %eax, 4(%esp)

        call printf
        leave
        ret
