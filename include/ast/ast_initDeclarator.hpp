#ifndef ast_initDeclarator_hpp
#define ast_initDeclarator_hpp

#include "ast_declarator.hpp"

// This is used for declarations which are initialised (int x = 3;)
// Basically a combination of declarator and binaryNormalAssign, but i'm too lazy to think
// of an elegant way to combine them so I'm just making a new class

class InitDeclarator
  : public Node
{
public:
  // Consturctor
  InitDeclarator(NodePtr declarator, NodePtr initializer);

  // Destructor
  virtual ~InitDeclarator();

  // Visualising
  void PrettyPrint(std::ostream &dst, std::string indent) const override;

  // Codegen + helpers
  void generateMIPS(std::ostream &dst, Context &context, int destReg) const override;
  void generateTypeMIPS(std::ostream &dst, Context &context, int destReg, enum Specifier type) const override;
  std::string getId() const override;
  bool isFunction() const override;
  bool isInit() const override;
  int getValue() const override;
  int getValue(int i) const override;
  double getFloat() const override;
  double getFloat(int i) const override;
  int getArraySize() const override;
};

#endif
