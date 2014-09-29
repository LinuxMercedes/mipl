#pragma once

#include<string>
#include<sstream>

enum Type {
  UNDEFINED,
  INT,
  CHAR,
  BOOL,
  ARRAY,
  PROCEDURE,
  PROGRAM
};

struct ArrayInfo {
  int start;
  int end;
};

struct TypeInfo {
  Type type;
  Type extended;
  ArrayInfo array;
};

struct VarInfo {
  TypeInfo type;
};

std::string pretty_type(const Type& t);

std::string pretty_typeinfo(const TypeInfo& t);

std::string pretty_varinfo(const VarInfo& v);

