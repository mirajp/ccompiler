main() {
    int i;
    i = 0;
    if(i < 10) {
        printf("Hi!\n");
        printf("i = %d which is less than 10!\n", i);
        i = 10;
    }
    
    if (i < 10) {
        printf("i = %d, which is still less than 10!\n", i);
    }
    else {
        printf("Aww, i = %d is no longer less than 10 =(\n", i);
    }
    
    return;
}
