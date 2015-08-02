main()
{   
    int a;
    int b;
    a = 1;
    a++;
    b = 2;
    b--;
    int c;
    c = a + b;
    c = c + a + b;
    int d;
    d = c * a + b;
    int e;
    e = a + b * c;
    
    g(a);
    
    printf("Hi");
    
    f();
    
    g();
    
    return 0;
}