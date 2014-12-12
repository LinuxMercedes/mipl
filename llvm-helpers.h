/* -*- mode: C++ -*- */
#pragma once

#include <iostream>
#include <vector>

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Instructions.h"

#include "varinfo.h"

using namespace llvm;

Value* GetOperation(IRBuilder<> Builder, OpType op, Value* a, Value* b) {
  Value* f = NULL;
  switch(op){
  case AND:
    f = Builder.CreateAnd(a, b, "and");
    break;
  case ADD:
    f = Builder.CreateAdd(a, b, "add");
    break;
  case SUB:
    f = Builder.CreateSub(a, b, "sub");
    break;
  case MULT:
    f = Builder.CreateMul(a, b, "mul");
    break;
  case DIV:
    f = Builder.CreateSDiv(a, b, "add");
    break;
  case OR:
    f = Builder.CreateOr(a, b, "sub");
    break;
  default:
    std::cerr << "We should never reach this in GetOperation" << std::endl;
    std::cerr << "Shouldn't have gotten a " << op << std::endl;
  }

  return f;
}

llvm::Type* GetType(VarInfo var) {
  llvm::Type* type = NULL;

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
    VarInfo v;
    v.type.type = var.type.extended;
    type = ArrayType::get(GetType(v), var.type.array.end - var.type.array.start + 1);
    break;
  default:
    std::cerr << "Uh.... we should never reach this spot." << std::endl;
    break;
  }

  return type;
}

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

  llvm::Type* type = GetType(var);
  Value* array_size = NULL;
  if (var.type.type == ARRAY) {
    array_size = CreateIntConst(var.type.array.end - var.type.array.end + 1);
  }

  return TmpB.CreateAlloca(type, array_size, name);
}

Function* CreateMain(Module* module) {
  FunctionType *FT = FunctionType::get(llvm::Type::getVoidTy(getGlobalContext()), false);
  return Function::Create(FT, Function::ExternalLinkage, "main", module);
}

Function* PrintfPrototype(LLVMContext& ctx, Module* module) {
  std::vector<llvm::Type*> printf_arg_types;
  printf_arg_types.push_back(llvm::Type::getInt8PtrTy(ctx));

  FunctionType* printf_type = FunctionType::get(llvm::Type::getInt32Ty(ctx), printf_arg_types, true);
  Function *func = Function::Create(printf_type, Function::ExternalLinkage, Twine("printf"), module);

  func->setCallingConv(llvm::CallingConv::C);
  return func;
}

Value* CreatePrintfFormat(LLVMContext& ctx, Module* module, const char* format) {
  Constant *format_const = ConstantDataArray::getString(ctx, format);
  llvm::Type *type = ArrayType::get(IntegerType::get(ctx, 8), strlen(format) + 1);
  GlobalVariable *var = new GlobalVariable(*module, type, true,
					   GlobalValue::PrivateLinkage,
					   format_const, ".str");
  Constant *zero = Constant::getNullValue(IntegerType::getInt32Ty(ctx));

  std::vector<Constant*> indices;
  indices.push_back(zero);
  indices.push_back(zero);
  return ConstantExpr::getGetElementPtr(var, indices);
}
