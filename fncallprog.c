main() {
	printf("Inside main\n");
	f();
	printf("Exiting main.\n");
	return;
}

f() {
	printf("Inside local function 'f'\n");
	printf("Exiting local function 'f'\n");
	return;
}
