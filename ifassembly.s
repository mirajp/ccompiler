.data
.LC0:
	.string "Hi!\n"
.LC1:
	.string "i = %d which is less than 10!\n"
.LC2:
	.string "i = %d, which is still less than 10!\n"
.LC3:
	.string "Aww, i = %d is no longer less than 10 =(\n"
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

# 	CMP %T1, $10
	movl -4(%ebp), %eax
	cmpl $10, %eax
# 	BRGE BB2
	jge BB2
# BB1:
BB1:
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

# 	ARG "i = %d which is less than 10!\n"
	movl $.LC1, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T3 = CALL printf
	call printf
	movl %eax, -12(%ebp)

# 	%T1 = MOV $10
	movl $10, %eax
	movl %eax, -4(%ebp)

# BB2:
BB2:
# 	CMP %T1, $10
	movl -4(%ebp), %eax
	cmpl $10, %eax
# 	BRGE BB4
	jge BB4
# BB3:
BB3:
# 	ARGBEGIN 2
	subl $12, %esp

# 	ARG "i = %d, which is still less than 10!\n"
	movl $.LC2, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T4 = CALL printf
	call printf
	movl %eax, -16(%ebp)

# BB4:
BB4:
# 	ARGBEGIN 2
	subl $12, %esp

# 	ARG "Aww, i = %d is no longer less than 10 =(\n"
	movl $.LC3, %eax
	movl %eax, 0(%esp)

# 	ARG %T1
	movl -4(%ebp), %eax
	movl %eax, 4(%esp)

# 	%T5 = CALL printf
	call printf
	movl %eax, -20(%ebp)

# 	RETURN 
	leave
	ret
# 
