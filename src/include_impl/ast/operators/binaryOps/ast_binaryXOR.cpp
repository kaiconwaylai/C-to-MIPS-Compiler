#include "ast/operators/binaryOps/ast_binaryXOR.hpp"

void BinaryXOR::PrettyPrint(std::ostream &dst, std::string indent) const
{
  dst << indent << "Binary XOR [ " << std::endl;
  dst << indent << "Left Op:" << std::endl;
  LeftOp()->PrettyPrint(dst, indent+"  ");
  std::cout << indent << "Right Op: " << std::endl;
  RightOp()->PrettyPrint(dst, indent+"  ");
  std::cout << indent << "]" <<std::endl;
}

void BinaryXOR::generateMIPS(std::ostream &dst, Context &context, int destReg) const
{
  
  int regLeft = DoLeft(dst, context, destReg);
  int regRight = DoRight(dst, context, destReg, regLeft);

  EZPrint(dst, "xor", destReg, regLeft, regRight);

  context.regFile.freeReg(regLeft);
  context.regFile.freeReg(regRight);
}
 
