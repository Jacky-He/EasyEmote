//
//  salloc.c
//  TestC
//
//  Created by Jacky He on 2020-11-22.
//

#include "salloc.h"

void *scalloc(size_t i1, size_t i2)
{
    void *newm = calloc(i1, i2);
    if (newm == NULL)
    {
        fprintf(stderr, "failed to calloc");
        abort();
    }
    return newm;
}

void *smalloc(size_t bytes)
{
    void *newm = malloc(bytes);
    if (newm == NULL)
    {
        fprintf(stderr, "failed to malloc");
        abort();
    }
    return newm;
}
