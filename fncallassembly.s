.data
.LC0:
	.string "Inside main\n"
.LC1:
	.string "Exiting main.\n"
.LC2:
	.string "Inside local function 'f'\n"
.LC3:
	.string "Exiting local function 'f'\n"
#  				
# main:
.text
.global main

main:
	pushl %ebp
	movl %esp, %ebp

# 	ARGBEGIN 1
	subl $8, %esp

# 	ARG "Inside main\n"
	movl $.LC0, %eax
	movl %eax, 0(%esp)

# 	%T1 = CALL printf
	call printf
	movl %eax, -4(%ebp)

# 	%T2 = CALL f
	call f
	movl %eax, -8(%ebp)

# 	ARGBEGIN 1
	subl $8, %esp

# 	ARG "Exiting main.\n"
	movl $.LC1, %eax
	movl %eax, 0(%esp)

# 	%T3 = CALL printf
	call printf
	movl %eax, -12(%ebp)

# 	RETURN 
	leave
	ret
# 
#  			
# f:
.text
.global f

f:
	pushl %ebp
	movl %esp, %ebp

# 	ARGBEGIN 1
	subl $8, %esp

# 	ARG "Inside local function 'f'\n"
	movl $.LC2, %eax
	movl %eax, 0(%esp)

# 	%T4 = CALL printf
	call printf
	movl %eax, -16(%ebp)

# 	ARGBEGIN 1
	subl $8, %esp

# 	ARG "Exiting local function 'f'\n"
	movl $.LC3, %eax
	movl %eax, 0(%esp)

# 	%T5 = CALL printf
	call printf
	movl %eax, -20(%ebp)

# 	RETURN 
	leave
	ret
# 
