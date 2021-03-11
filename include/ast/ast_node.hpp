#ifndef ast_node_hpp
#define ast_node_hpp

#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>

// Base building block for everything, the Argos

class Node;
typedef Node *NodePtr;

class Node
{
protected:
  std::vector<NodePtr> branches;

public:
  // Used in derived classes
  Node(std::vector<NodePtr> _branches);
  Node();

  virtual ~Node();

  // Visualising
  virtual void PrettyPrint(std::ostream &dst, std::string indent) const = 0;

  // We friends with ostream now :D
  friend std::ostream& operator<<(std::ostream &dst, const Node &Node);
  friend std::ostream& operator<<(std::ostream &dst, const NodePtr Node);
};

// idk wtf this is lmao
/*
struct CompileContext
{
    std::map<std::string,int32_t> bindings;
};
*/

#endif