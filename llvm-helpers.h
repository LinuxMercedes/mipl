#pragma once

#include <iostream>

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

Value* CreateIntConst(int value) {
  return ConstantInt::get(getGlobalContext(), APInt(32, value));
}

Value* CreateCharConst(char value) {
  unsigned int i = (unsigned int)value;
  return ConstantInt::get(getGlobalContext(), APInt(8, i));
}

Value* CreateBoolConst(int value) {
  if (value == 0) {
    return ConstantInt::getFalse(getGlobalContext());
  } else if (value == 1) {
    return ConstantInt::getTrue(getGlobalContext());
  }

  std::cerr << "Uh... we should never reach this spot." << std::endl;
  return NULL;
}

AllocaInst* CreateEntryBlockAlloca(Function* TheFunction, const char* name, VarInfo var) {
    IRBuilder<> TmpB(&TheFunction->getEntryBlock(), TheFunction->getEntryBlock().begin());

    llvm::Type* type;
    Value* array_size = NULL;
    switch(var.type.type) {
      case INT:
	type = llvm::Type::getInt32Ty(getGlobalContext());
	break;
      case CHAR:
	type = llvm::Type::getInt8Ty(getGlobalContext());
	break;
      case BOOL:
	type = llvm::Type::getInt1Ty(getGlobalContext());
	break;
      case ARRAY:
	type = llvm::Type::getInt1Ty(getGlobalContext());
	break;
      default:
	std::cerr << "Uh.... we should never reach this spot." << std::endl;
	break;
    }

    return TmpB.CreateAlloca(type, array_size, name);
}
