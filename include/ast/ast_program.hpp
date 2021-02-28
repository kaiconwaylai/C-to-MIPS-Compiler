#ifndef ast_program_hpp
#define ast_program_hpp

class Program;

typedef const Program *ProgramPtr;

class Program
{
public:
    virtual ~Program();
    friend std::ostream& operator<<(std::ostream &os, const Program& program);

protected:
    virtual void PrettyPrint(std::ostream &os) const = 0;
    std::vector<ProgramPtr> branches;
}

ProgramPtr Parse(
    std::istream &src
);

void PrettyPrint(
    std::ostream &dst,
    ProgramPtr node,
    std::string indent=""
);

struct CompileContext
{
    std::vector<int32_t> params;
    std::map<std::string,int32_t> bindings;
};

void Compile(
    ProgramPtr program,
    CompileContext &context
);

#endif