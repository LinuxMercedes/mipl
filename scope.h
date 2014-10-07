#pragma once

#include "varinfo.h"
#include <string>
#include <map>
#include <list>
#include <stdio.h>

#define SCOPE_PRINTING

typedef std::map<std::string, VarInfo> SymbolTable;

class Scope {
  public:
    Scope();
    void push();
    void pop();
    bool add(const std::string& name, const VarInfo& v);
    VarInfo get(const std::string& name);
  private:
    std::list<SymbolTable> scope;
};

