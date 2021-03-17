#ifndef ast_binaryXORAss_hpp
#define ast_binaryXORAss_hpp

#include "ast/operators/ast_binaryOperation.hpp"

class BinaryXORAss
    : public BinaryOperation
{
public:

    using BinaryOperation::BinaryOperation;

    virtual void PrettyPrint(std::ostream &dst, std::string indent) const override;


};

#endif
