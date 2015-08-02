// ECE466 - Hash Table for Symbol Tables for a parser for a C compiler
// Miraj Patel, Hash Table implementation taken from DSA2 (ECE 165)

#include "hash.h"

#define FALSE   0
#define TRUE    1


// lookup table for large primes to use as table size
static int primeTable[10] = {1009, 2017, 4049, 8101, 16217,
                                        32441, 64891, 196613, 393241, 786433};


struct hashTable *new_hashTable(int size) {
    struct hashTable *table;
    if ( (table = malloc(sizeof(struct hashTable))) == NULL ) {
        fprintf(stderr, "Error allocating memory for new hash table: '%s'\n", strerror(errno));
        return NULL;
    }
    
    table->capacity = getPrime(size);
    table->filled = 0;
    
    if ( (table->data = malloc((table->capacity)*sizeof(struct hashItem))) == NULL ) {
        fprintf(stderr, "Error allocating memory for %d hash items inside new hash table: '%s'\n", table->capacity, strerror(errno));
        return NULL;
    }
    
    int i;
    for (i = 0; i < table->capacity; i++) {
        table->data[i].isOccupied = FALSE;
        table->data[i].isDeleted = FALSE;
        table->data[i].key = NULL;
        table->data[i].pv = NULL;
    }
    
    return table;
}

// Insert the specified key into the hash table. If an optional pointer is provided, associate that pointer with the key.
// Returns 0 on success, 1 if key already exists in hash table, 2 if hash table is full.
int insert(struct hashTable *theTable, char *key, void *pv) {
    // Make sure hash table is not full
    if (theTable->filled == theTable->capacity)
        return 2;
    
    // Compute index for the key, and see if it's available, else find next available index
    int index = hash(theTable, key);
    while (theTable->data[index].isOccupied) {
        if ( !strcmp(theTable->data[index].key, key) && !theTable->data[index].isDeleted )
            return 1;
        
        index = ((index+1) % (theTable->capacity));
    }
    
    theTable->data[index].key = key;
    theTable->data[index].isOccupied = TRUE;
    theTable->data[index].isDeleted = FALSE;
    theTable->data[index].pv = pv;
    theTable->filled++;
    
    if (theTable->filled > (theTable->capacity*3/4) ) {
        // Needs at half full, rehashing with larger table would be ideal
        fprintf(stderr, "Hash table is more than 75%% full\n");
    }
    if (theTable->filled == theTable->capacity) {
        fprintf(stderr, "Warning: Hash table is now full!\n");
        //return 2;
    }
    return 0;
}

// Check if the specified key is in the hash table. If so, return TRUE; otherwise, return FALSE.
int contains(struct hashTable *theTable, char *key) {
    int index = findPos(theTable, key);
    if (index == -1)
        return FALSE;
    else
        return TRUE;
}

// Get the pointer associated with the specified key.
// If the key does not exist in the hash table, return NULL.
// If an optional pointer to a int is provided,
// set the int to TRUE if the key is in the hash table,
// and set the int to FALSE otherwise.
void* getPointer(struct hashTable *theTable, char *key, int *b) {
    int index = findPos(theTable, key);
    if (index == -1) {
        if (b)
            *b = FALSE;
        return NULL;
    }
    else {
        if (b)
            *b = TRUE;
        return theTable->data[index].pv;
    }
}

// Set the pointer associated with the specified key.
// Returns 0 on success,
// 1 if the key does not exist in the hash table.
int setPointer(struct hashTable *theTable, char *key, void *pv) {
    int index = findPos(theTable, key);
    if (index == -1) 
        return 1;
    else {
        theTable->data[index].pv = pv;
        return 0;
    }
}

// Delete the item with the specified key. Returns TRUE on success, FALSE if the specified key is not in the hash table.
int removeItem(struct hashTable *theTable, char *key) {
    int index = findPos(theTable, key);
    if (index == -1)
        return FALSE;
    else {
        theTable->data[index].isDeleted = TRUE;
        theTable->data[index].pv = NULL;
        return TRUE;
    }
}

void printTable(struct hashTable *theTable) {
    int i;
    for (i = 0; i < theTable->capacity; i++) {
        fprintf(stderr, "%dth key = %s\n", i, theTable->data[i].key);
    }
}

// Private Member Functions
// The actual hash function
int hash(struct hashTable *theTable, char *key) {
    // 5381 is good starting constant according to multiple sources
    unsigned long hash = 5381;
    unsigned int i,c;
    
    for (i = 0; i < strlen(key); i++) {
        c = (int) key[i];
        hash = ((hash << 5) + hash) + c; // Basically: hash*33 + c
    }
    
    return (hash % (theTable->capacity));
}

// Search for an item with the specified key. Return the position if found, -1 otherwise.
int findPos(struct hashTable *theTable, char *key) {
    int index = hash(theTable, key);
    
    while(theTable->data[index].isOccupied) {
        // If key found:
        if ( !strcmp(theTable->data[index].key, key) && !theTable->data[index].isDeleted )
            return index;
        else {
            index++;
            index = (index % (theTable->capacity));
        }
    }
    
    // Key not found
    return -1;
}

/*
// Makes the hash table bigger. Returns TRUE on success, FALSE if memory allocation fails.
(C++ code from DSA Assignment)
int hashTable::rehash() {
    //cout << "Rehashing..." << endl;
    int prevSize = capacity;
    capacity = getPrime(prevSize);
    
    std::vector<hashItem> oldTable(0);
    oldTable.swap(data);
    data.resize(capacity);
    filled = 0;
    
    if (data.size() == capacity) {
        capacity = capacity;
        for (int i = 0; i < prevSize; i++) {
            if (oldTable[i].isOccupied)
                insert(oldTable[i].key, oldTable[i].pv);
        }
        oldTable.clear();
        // shrink to fit is supposed reduce its capacity to its current size (0), but compile error of function not found
        // oldTable.shrink_to_fit();
        // swap with its temporary self - once out of score, oldTable's memory allocation reduces to that of the temp
        oldTable.swap(oldTable);
        return TRUE;
    }
    else {
        return FALSE;
    }
}
*/


// Return a prime number at least as large as size. Uses a precomputed sequence of selected prime numbers.
unsigned int getPrime(int size) {
    int i = 0;
    while (size >= primeTable[i])
        i++;
    return primeTable[i];
}

