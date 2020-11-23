//
//  vector.c
//  TestC
//
//  Created by Jacky He on 2020-11-22.
//

#include "vector.h"

typedef struct vector vector;
struct vector
{
    size_t size; //size < capacity
    size_t capacity; //>= 1
    char *arr;
};

vector* v_new()
{
    vector *res = smalloc(sizeof(vector));
    res -> capacity = 1;
    res -> size = 0;
    res -> arr = smalloc(sizeof(char));
    return res;
}

void resize(vector *v, size_t capacity)
{
    char *new = smalloc(sizeof(char)*capacity);
    for (int i = 0; i < v -> size; i++) new [i] = v -> arr[i];
    free(v -> arr);
    v -> arr = new;
    v -> capacity = capacity;
}

void vpush_back(vector* v, char c)
{
    v -> arr[v -> size] = c;
    (v -> size)++;
    if (v -> size == v -> capacity) resize(v, 2*(v -> capacity));
}

char vpop_back(vector* v)
{
    (v -> size)--;
    if (v -> size == 0) return v -> arr[v -> size];
    if (v -> size == (v -> capacity)/4) resize(v, (v -> capacity)/2);
    return v -> arr[v -> size];
}

size_t vsize(vector* v)
{
    return v -> size;
}

char velem_at(vector* v, size_t i)
{
    return v -> arr[i];
}

void vfree(vector* v)
{
    free(v -> arr);
    free(v);
}

bool vempty(vector* v)
{
    return v -> size == 0;
}

void vclear(vector* v)
{
    while (!vempty(v)) vpop_back(v);
}
