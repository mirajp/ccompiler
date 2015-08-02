#ifndef _HASH_H
#define _HASH_H

// ECE466 - Hash Table for Symbol Tables for a Parser for a C Compiler
// Miraj Patel, Hash Table implementation taken from DSA2 (ECE 165)

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>


// Each item in the hash table contains:
// key - a string used as a key.
// isOccupied - if false, this entry is empty,
//              and the other fields are meaningless.
// isDeleted - if true, this item has been lazily deleted.
// pv - a pointer related to the key;
// NULL if no pointer was provided to insert.
struct hashItem {
    int isOccupied;
    int isDeleted;
    char *key;
    void *pv;
};

struct hashTable {
    unsigned int capacity; // The current capacity of the hash table.
    unsigned int filled; // Number of occupied items in the table.
    struct hashItem *data; // The actual entries are here. (The symbols/identifiers associated with this scope
};

struct hashTable *new_hashTable(int size);

// Insert the specified key into the hash table.
// If an optional pointer is provided,
// associate that pointer with the key.
// Returns 0 on success,
// 1 if key already exists in hash table,
// 2 if hash table is full.
int insert(struct hashTable *theTable, char *key, void *pv);

// Check if the specified key is in the hash table.
// If so, return true (1); otherwise, return false (0).
int contains(struct hashTable *theTable, char *key);

// Get the pointer associated with the specified key.
// If the key does not exist in the hash table, return NULL.
// If an optional pointer to a bool is provided,
// set the bool to true if the key is in the hash table,
// and set the bool to false otherwise.
void *getPointer(struct hashTable *theTable, char *key, int *b);

// Set the pointer associated with the specified key.
// Returns 0 on success,
// 1 if the key does not exist in the hash table.
int setPointer(struct hashTable *theTable, char *key, void *pv);

// Delete the item with the specified key.
// Returns true (1) on success,
// false (0) if the specified key is not in the hash table.
int removeItem(struct hashTable *theTable, char *key);

// The hash function.
int hash(struct hashTable *theTable, char *key);

// Search for an item with the specified key.
// Return the position if found, -1 otherwise.
int findPos(struct hashTable *theTable, char *key);

// The rehash function; makes the hash table bigger.
// Returns true (1) on success, false (0) if memory allocation fails.
// int rehash(struct hashTable *theTable);
// Deciding not to implement

// Return a prime number at least as large as size.
// Uses a precomputed sequence of selected prime numbers.
static unsigned int getPrime(int size);

void printTable(struct hashTable *theTable);

#endif //_HASH_H
