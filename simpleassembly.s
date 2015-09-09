.data
.LC0:
	.string "hello: x = 50, now x + 10 = %d\n"
.LC1:
	.string "Now x*2 = %d\n"
.LC2:
	.string "Now x/2 = %d\n"
.LC3:
	.string "Now x-2 = %d\n"
#                                                                  
# main:
.text
.global main

main:
	pushl %ebp
	movl %esp, %ebp
	subl $20, %esp

# 	%T1 = MOV $50
	movl $50, %eax
	movl %eax, -4(%ebp)

# 	%T1 = ADD %T1, $10
	movl -4(%ebp), %eax
	movl $10, %edx
	add %eax, %edx
	movl %edx, -4(%ebp)

# 	%T1 = MOV %T1
	movl -4(%ebp), %eax
	movl %eax, -4(%ebp)

# 	ARGBEGIN 2
	subl $8, %esp

# 	ARG "hello: x = 50, now x + 10 = %d\n"
	movl $.LC0, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T2 = CALL printf
	call printf
	movl %eax, -8(%ebp)
	addl $8, %esp

# 	%T1 = MUL %T1, $2
	movl -4(%ebp), %eax
	movl $2, %edx
	imul %eax, %edx
	movl %edx, -4(%ebp)

# 	%T1 = MOV %T1
	movl -4(%ebp), %eax
	movl %eax, -4(%ebp)

# 	ARGBEGIN 2
	subl $8, %esp

# 	ARG "Now x*2 = %d\n"
	movl $.LC1, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T3 = CALL printf
	call printf
	movl %eax, -12(%ebp)
	addl $8, %esp

# 	%T1 = DIV %T1, $2
	movl $0, %edx
	movl -4(%ebp), %eax
	movl $2, %ecx
	idivl %ecx
	movl %eax, -4(%ebp)

# 	%T1 = MOV %T1
	movl -4(%ebp), %eax
	movl %eax, -4(%ebp)

# 	ARGBEGIN 2
	subl $8, %esp

# 	ARG "Now x/2 = %d\n"
	movl $.LC2, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T4 = CALL printf
	call printf
	movl %eax, -16(%ebp)
	addl $8, %esp

# 	%T1 = SUB %T1, $2
	movl -4(%ebp), %eax
	movl $2, %edx
	sub %edx, %eax
	movl %eax, -4(%ebp)

# 	%T1 = MOV %T1
	movl -4(%ebp), %eax
	movl %eax, -4(%ebp)

# 	ARGBEGIN 2
	subl $8, %esp

# 	ARG "Now x-2 = %d\n"
	movl $.LC3, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T5 = CALL printf
	call printf
	movl %eax, -20(%ebp)
	addl $8, %esp

# 	RETURN 
	leave
	ret
# 
