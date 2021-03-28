#include "ast/ast_declaration.hpp"

// Constructors
Declaration::Declaration(NodePtr type, NodePtr id)
{
  branches.push_back(type);
  branches.push_back(id);
}

Declaration::Declaration(NodePtr type)
  : Declaration(type, new Identifier("<NULL>"))
{}

// Destructor
Declaration::~Declaration()
{
  delete branches[0];
  delete branches[1];
}

// Visualising
void Declaration::PrettyPrint(std::ostream &dst, std::string indent) const
{
  dst << indent << "Declaration [" << std::endl;
  dst << indent+"  " << "Type: ";
  branches[0]->PrettyPrint(dst, indent+"  ");
  branches[1]->PrettyPrint(dst, indent+"  ");
  dst << indent << "]" << std::endl;
}

// Codegen + helpers
void Declaration::generateMIPS(std::ostream &dst, Context &context, int destReg) const
{
  // Check the type of branches[1] to see if it's a variable / function declaration
  if(branches[1]->isFunction()){
    // Deals with function declaration
    std::string id = branches[1]->getNode(0)->getId(); // Function id
    unsigned argSize = 0; // Total size of arguments
    unsigned i = 0;
    NodePtr param = branches[1]->getNode(1)->getNode(i); // Gets parameters in declaration
    while(param != NULL){
      unsigned size = param->getSize();
      context.functions[id].argSize.push_back(size); // Stores size of individual parameters in order
      argSize += size;
      i++;
      param = branches[1]->getNode(1)->getNode(i);
    }
    if(argSize < 16 && argSize > 0){
      argSize = 16;
    }
    context.functions[id].size = argSize; // All information associated with declaration now stored for function calls
  }
  else if(branches[1]->getArraySize() != 0 ){ // checks if we are declaring an array
    unsigned arraysize = branches[1]->getArraySize();
    unsigned varsize = branches[0]->getSize();
    std::string id = branches[1]->getId();

    if(branches[1]->isInit()){
      context.stack.back().offset += arraysize*varsize; // creates space for all the arrays children
      dst << "addiu $29,$29,-" << arraysize*varsize << std::endl; // Decrements stack pointer
      context.stack.back().varBindings[id] = {varsize, -context.stack.back().offset, -1, "_int"}; // stores the space allocated (currently not available in a register)
      branches[1]->generateMIPS(dst, context, destReg);
    }
    else{
      if(arraysize != -1){ // if arraysize = 0 then either something is wrong or its gonna be initialised, either way dont know size
        context.stack.back().offset += arraysize*varsize; // creates space for all the arrays children
        dst << "addiu $29,$29,-" << arraysize*varsize << std::endl; // Decrements stack pointer
        context.stack.back().varBindings[id] = {varsize, -context.stack.back().offset, -1, "_int"}; // stores the space allocated (currently not available in a register)
      }else{
        // im not gonna deal with this now.
      }
    }

  }
  else{
    // Deals with variable declaration (will probs have to extend for globals)
    unsigned size = branches[0]->getSize(); // Size of variable
    std::string id = branches[1]->getId(); // Variable id
    context.stack.back().offset += size; // Increments size of frame to have space for variable, will actually store it when its value is assigned
    dst << "addiu $29,$29,-" << size << std::endl; // Decrements stack pointer

    // If the variable is being initialised (will be similar to assignment operator)
    if(branches[1]->isInit()){
      // Ensures a free register is being used
      if(context.regFile.usedRegs[destReg]){
        destReg = context.allocate();
      }
      branches[1]->generateMIPS(dst, context, destReg); // Evaluates initializer into allocated register
      if( branches[1]->getNode(0)->isPtr() ){
        context.stack.back().varBindings[id] = {size, -context.stack.back().offset, destReg, "_ptr"}; // stores the space allocated
      }else{
        context.stack.back().varBindings[id] = {size, -context.stack.back().offset, destReg, "_int"}; // stores the space allocated
      }
      context.regFile.useReg(destReg); // Indicates register is being used
      dst << "sw $" << destReg << ",0($29)" << std::endl; // Stores variable in memory allocated
    }

    // Variable is not initialised, space is allocated and everything is stored in context for intialisation
    else{
      if( branches[1]->isPtr() ){
        context.stack.back().varBindings[id] = {size, -context.stack.back().offset, -1, "_ptr"}; // labels it a ptr
      }else{
        context.stack.back().varBindings[id] = {size, -context.stack.back().offset, -1, "_int"}; // stores the space allocated (currently not available in a register)
      }
    }
  }
}

// Helpers
NodePtr Declaration::getNode(unsigned index) const
{
  if(index < branches.size()){
    return branches[index];
  }
  return NULL;
}

int Declaration::getSize() const
{
  return branches[0]->getSize();
}

std::string Declaration::getId() const
{
  return branches[1]->getId();
}

bool Declaration::isFunction() const
{
  return branches[1]->isFunction();
}

bool Declaration::isInit() const
{
  return branches[1]->isInit();
}

int Declaration::getArraySize() const
{
  return branches[1]->getArraySize();
}

int Declaration::getValue() const
{
  return branches[1]->getValue();
}

int Declaration::getValue(int i) const
{
  return branches[1]->getValue(i);
}
