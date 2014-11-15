/* -*- mode: c++ -*- */
/**
 * CS 356 Assignment 4: Semantic analysis for MIPL
 *
 * Description: This is a stack for maintaining symbol tables
 *
 * Author: Michael Wisely
 * Date: October 8, 2014
 */

#include <map>
#include <list>
#include <string>
#include <stdio.h>

#include "var.h"

typedef std::map<std::string, Var> SymbolTable;

class SymbolTableStack {

public:
  bool contains(char* key);
  Var get(char* key);
  bool containsLocal(char* key);
  void setLocal(char* key, Var var);
  void openScope();
  void closeScope();
  int size();

private:
  std::list<SymbolTable> stStack;
};

bool SymbolTableStack::contains(char* key) {
  std::string skey(key);
  std::list<SymbolTable >::iterator it;
  for (it=stStack.begin(); it != stStack.end(); ++it) {
    if (it->count(key) == 1) {
      return true;
    }
  }
  return false;
}

Var SymbolTableStack::get(char* key) {
  std::string skey(key);
  std::list<SymbolTable >::iterator it;
  for (it=stStack.begin(); it != stStack.end(); ++it) {
    if (it->count(key) == 1) {
      return (*it)[key];
    }
  }
  throw "Not found";
}

bool SymbolTableStack::containsLocal(char* key) {
  std::string skey(key);
  return stStack.front().count(key) == 1;
}

void SymbolTableStack::setLocal(char* key, Var var) {
  stStack.front()[key] = var;
}

void SymbolTableStack::openScope() {
  SymbolTable m;
  stStack.push_front(m);
}

void SymbolTableStack::closeScope() {
  stStack.pop_front();
}

int SymbolTableStack::size() {
  return stStack.size();
}
