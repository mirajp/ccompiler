.data
.LC0:
	.string "Hi!\n"
.LC1:
	.string "i = %d\n"
#                                                     
# main:
.text
.global main

main:
	pushl %ebp
	movl %esp, %ebp

# 	%T1 = MOV $0
	movl $0, %eax
	movl %eax, -4(%ebp)

# BB1:
BB1:
# 	CMP %T1, $10
	movl -4(%ebp), %eax
	cmpl $10, %eax
# 	BRGE BB3
	jge BB3
# BB2:
BB2:
# 	ARGBEGIN 1
	subl $8, %esp

# 	ARG "Hi!\n"
	movl $.LC0, %eax
	movl %eax, 0(%esp)

# 	%T2 = CALL printf
	call printf
	movl %eax, -8(%ebp)

# 	ARGBEGIN 2
	subl $12, %esp

# 	ARG "i = %d\n"
	movl $.LC1, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T3 = CALL printf
	call printf
	movl %eax, -12(%ebp)

# 	%T1 = ADD %T1, $1
	movl -4(%ebp), %eax
	movl $1, %edx
	add %eax, %edx
	movl %edx, -4(%ebp)

# 	JMP BB1
	jmp BB1
# BB3:
BB3:
# 	RETURN 
	leave
	ret
# 
