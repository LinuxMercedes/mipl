#include "scope.h"

Scope::Scope() {
}

void Scope::push() {
  SymbolTable s;
  scope.push_front(s);
#ifdef SCOPE_PRINTING
  printf("\n___Entering new scope...\n\n");
#endif
}

void Scope::pop() {
  scope.pop_front();
#ifdef SCOPE_PRINTING
  printf("\n___Exiting scope...\n\n");
#endif
}

bool Scope::add(const std::string& name, const VarInfo& v) {
#ifdef SCOPE_PRINTING
   std::string s = pretty_varinfo(v);
   printf("___Adding %s to symbol table with type %s\n", name.c_str(), s.c_str());
#endif

   if(scope.front().find(name) != scope.front().end()) {
     return false;
   }
   
   scope.front()[name] = v;
   return true;
}

VarInfo Scope::get(const std::string& name) {
  for(auto it = scope.begin(); it != scope.end(); it++) {
    if(it->find(name) != it->end()) {
      return it->at(name);
    }
  }

  VarInfo v;
  v.type.type = UNDEFINED;
  return v;
}

