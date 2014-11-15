/* -*- mode: c -*- */
/**
 * CS 356 Assignment 4: Semantic analysis for MIPL
 *
 * Description: This is a singly linked list for storing a list of strings
 *
 * Author: Michael Wisely
 * Date: October 8, 2014
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

typedef struct node {
  char *string;
  struct node *next;
} string_list_node;

string_list_node* newStringList();
string_list_node* deleteStringList(string_list_node* list);
string_list_node* addString(string_list_node* list, char *string);

string_list_node* newStringList() {
  return NULL;
}

string_list_node* deleteStringList(string_list_node* node) {
  if (node != NULL) {
    deleteStringList(node->next);
    free(node->string);
    free(node);
  }

  return NULL;
}

string_list_node* addString(string_list_node* list, char *string) {
  string_list_node *next = list;

  list = (string_list_node*)malloc(sizeof(string_list_node));
  list->next = next;
  list->string = strdup(string);
  return list;
}
