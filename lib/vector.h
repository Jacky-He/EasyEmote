//
//  vector.h
//  TestC
//
//  Created by Jacky He on 2020-11-22.
//

#ifndef vector_h
#define vector_h

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "salloc.h"

typedef struct vector* vector_t;

vector_t v_new(void);
void vpush_back(vector_t v, char c);
char vpop_back(vector_t v);
char velem_at(vector_t v, size_t i);
void vfree(vector_t v);
bool vempty(vector_t v);
void vclear(vector_t v);
size_t vsize(vector_t v);

#endif /* vector_h */
