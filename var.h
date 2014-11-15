/* -*- mode: c++ -*- */
/**
 * CS 356 Assignment 4: Semantic analysis for MIPL
 *
 * Description: This is a helper class for storing variables in the
 * symbol table
 *
 * Author: Michael Wisely
 * Date: October 8, 2014
 */

class Var {

public:
  std::string ident;
  int type;
  int array_type;

  bool operator< (const Var& other);
};

bool Var::operator<(const Var& other) {
  return this->ident.compare(other.ident) < 0;
}
