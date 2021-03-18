#include "ast/blocks/ast_while.hpp"

While::While(NodePtr condition, NodePtr scope)
{
  branches.push_back(condition);
  branches.push_back(scope);
}

While::~While()
{
  delete branches[0];
  delete branches[1];
}

NodePtr While::getCondition() const
{
  return branches[0];
}

NodePtr While::getScope() const
{
  return branches[1];
}

void While::PrettyPrint(std::ostream &dst, std::string indent) const
{
  dst << indent << "While condition [" << std::endl;
  branches[0]->PrettyPrint(dst, indent+"  ");
  dst << indent << "] endCondition" << std::endl;
  dst << indent << "Do scope [" << std::endl;
  branches[1]->PrettyPrint(dst, indent+"  ");
  dst << indent << "] endScope" << std::endl;
}