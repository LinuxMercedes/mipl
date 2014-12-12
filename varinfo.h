#pragma once

#include<string>
#include<sstream>
#include "llvm/IR/Instructions.h"

enum Type {
  UNDEFINED,
  INT,
  CHAR,
  BOOL,
  ARRAY,
  PROCEDURE,
  PROGRAM
};

enum OpType {
  LT,
  LE,
  NE,
  EQ,
  GT,
  GE,
  ADD,
  SUB,
  MULT,
  DIV,
  AND,
  OR
};

struct ArrayInfo {
  int start;
  int end;
};

struct TypeInfo {
  Type type;
  Type extended;
  ArrayInfo array;
  OpType op;
  llvm::Value* value;
};

struct VarInfo {
  TypeInfo type;
  unsigned int nest_level;
  unsigned int level;
  llvm::Value* value;
  llvm::Function* func;
};

std::string pretty_type(const Type& t) {
  switch(t) {
    case UNDEFINED:
      return "UNDEFINED";
    case INT:
      return "INTEGER";
    case CHAR:
      return "CHAR";
    case BOOL:
      return "BOOLEAN";
    case ARRAY:
      return "ARRAY";
    break;
    case PROCEDURE:
      return "PROCEDURE";
    case PROGRAM:
      return "PROGRAM";
  }
}

std::string pretty_typeinfo(const TypeInfo& t) {
  switch(t.type) {
    case ARRAY: {
      std::stringstream ss;
      ss << pretty_type(t.type)
	 << " "
	 << t.array.start
	 << " .. "
	 << t.array.end
	 << " OF "
	 << pretty_type(t.extended);
      return ss.str();
    }
    default:
      return pretty_type(t.type);
  }
}

std::string pretty_varinfo(const VarInfo& v) {
  return pretty_typeinfo(v.type);
}
