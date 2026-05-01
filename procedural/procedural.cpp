#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <memory>
#include <cctype>

using namespace std;

enum ValType { INT_VAL, BOOL_VAL, FUNC_VAL };
enum NodeType { N_INT, N_BOOL, N_ID, N_IF, N_LET, N_LAMBDA, N_CALL, N_DEFINE, N_COND };
enum ErrType { NO_ERR, PARSE_ERR, UNDECLARED_ERR, ARITY_ERR, TYPE_ERR, DIV_ZERO_ERR };

struct Node;
struct Env;
struct Func;
struct Val;

struct LetPair {
    string name;
    Node* expr;
};

struct CondPart {
    bool isElse;
    Node* test;
    Node* answer;
};

struct Node {
    NodeType kind;
    int num;
    bool tf;
    string word;
    vector<string> names;
    vector<Node*> list;
    vector<LetPair> lets;
    vector<CondPart> conds;
    Node* a;
    Node* b;
    Node* c;

    Node() {
        kind = N_INT;
        num = 0;
        tf = false;
        a = nullptr;
        b = nullptr;
        c = nullptr;
    }
};

struct Func {
    bool builtin;
    string op;
    vector<string> params;
    Node* body;
    Env* saved;

    Func() {
        builtin = false;
        body = nullptr;
        saved = nullptr;
    }
};

struct Val {
    ValType type;
    int num;
    bool tf;
    Func* fn;

    Val() {
        type = INT_VAL;
        num = 0;
        tf = false;
        fn = nullptr;
    }
};

struct Env {
    map<string, Val> table;
    Env* up;

    Env() {
        up = nullptr;
    }
};

vector<string> toks;
size_t posi = 0;
ErrType err = NO_ERR;
vector<unique_ptr<Node>> madeNodes;
vector<unique_ptr<Func>> madeFuncs;
vector<unique_ptr<Env>> madeEnvs;

Node* newNode() {
    madeNodes.push_back(make_unique<Node>());
    return madeNodes.back().get();
}

Func* newFunc() {
    madeFuncs.push_back(make_unique<Func>());
    return madeFuncs.back().get();
}

Env* newEnv(Env* parent) {
    madeEnvs.push_back(make_unique<Env>());
    madeEnvs.back()->up = parent;
    return madeEnvs.back().get();
}

void setErr(ErrType e) {
    if (err == NO_ERR) err = e;
}

bool isIntTok(const string& s) {
    if (s.empty()) return false;
    int i = 0;
    if (s[0] == '-') {
        if (s.size() == 1) return false;
        i = 1;
    }
    for (; i < (int)s.size(); i++) {
        if (!isdigit((unsigned char)s[i])) return false;
    }
    return true;
}

bool isBoolTok(const string& s) {
    return s == "#t" || s == "#f";
}

bool isBadName(const string& s) {
    return s == "if" || s == "let" || s == "lambda" || s == "define" || s == "cond" || s == "else";
}

bool goodName(const string& s) {
    if (s.empty()) return false;
    if (s == "(" || s == ")") return false;
    if (isIntTok(s) || isBoolTok(s) || isBadName(s)) return false;
    return true;
}

string errName(ErrType e) {
    if (e == PARSE_ERR) return "PARSE_ERROR";
    if (e == UNDECLARED_ERR) return "UNDECLARED_IDENTIFIER";
    if (e == ARITY_ERR) return "WRONG_ARITY";
    if (e == TYPE_ERR) return "TYPE_MISMATCH";
    if (e == DIV_ZERO_ERR) return "DIVISION_BY_ZERO";
    return "";
}

string typeName(ValType t) {
    if (t == INT_VAL) return "int";
    if (t == BOOL_VAL) return "bool";
    return "function";
}

string showVal(const Val& v) {
    if (v.type == INT_VAL) return to_string(v.num);
    if (v.type == BOOL_VAL) return v.tf ? "#t" : "#f";
    return "<function>";
}

Val makeInt(int x) {
    Val v;
    v.type = INT_VAL;
    v.num = x;
    return v;
}

Val makeBool(bool x) {
    Val v;
    v.type = BOOL_VAL;
    v.tf = x;
    return v;
}

Val makeFuncVal(Func* f) {
    Val v;
    v.type = FUNC_VAL;
    v.fn = f;
    return v;
}

bool needInt(const Val& v) {
    if (v.type != INT_VAL) {
        setErr(TYPE_ERR);
        return false;
    }
    return true;
}

bool needBool(const Val& v) {
    if (v.type != BOOL_VAL) {
        setErr(TYPE_ERR);
        return false;
    }
    return true;
}

bool findVar(Env* e, const string& name, Val& out) {
    while (e != nullptr) {
        auto it = e->table.find(name);
        if (it != e->table.end()) {
            out = it->second;
            return true;
        }
        e = e->up;
    }
    return false;
}

vector<string> splitTokens(const string& text) {
    /*visual aid of what is happenning here 
    (let x 5)
    out{
        (   
        let
        x
        5
        )
    }
    */
    vector<string> out;
    int i = 0;
    while (i < (int)text.size()) {
        while (i < (int)text.size() && isspace((unsigned char)text[i])) i++;
        if (i >= (int)text.size()) break;

        if (text[i] == '(' || text[i] == ')') {
            out.push_back(string(1, text[i]));
            i++;
            continue;
        }

        int j = i;
        while (j < (int)text.size() && !isspace((unsigned char)text[j]) && text[j] != '(' && text[j] != ')') j++;
        out.push_back(text.substr(i, j - i));
        i = j;
    }
    return out;
}

bool eat(const string& s) {
    if (posi < toks.size() && toks[posi] == s) {
        posi++;
        return true;
    }
    return false;
}

bool done() {
    return posi >= toks.size();
}

string nowTok() {
    if (done()) return "";
    return toks[posi];
}

Node* parseExpr();

Node* parseList() {
    if (!eat("(")) {
        setErr(PARSE_ERR);
        return nullptr;
    }
    if (done()) {
        setErr(PARSE_ERR);
        return nullptr;
    }

    string head = nowTok();

    if (head == "if") {
        posi++;
        Node* n = newNode();
        n->kind = N_IF;
        n->a = parseExpr();
        n->b = parseExpr();
        n->c = parseExpr();
        if (err != NO_ERR || n->a == nullptr || n->b == nullptr || n->c == nullptr || !eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        return n;
    }

    if (head == "let") {
        posi++;
        Node* n = newNode();
        n->kind = N_LET;
        if (!eat("(")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        while (!done() && nowTok() != ")") {
            if (!eat("(")) {
                setErr(PARSE_ERR);
                return nullptr;
            }
            if (done() || !goodName(nowTok())) {
                setErr(PARSE_ERR);
                return nullptr;
            }
            LetPair p;
            p.name = nowTok();
            posi++;
            p.expr = parseExpr();
            if (err != NO_ERR || p.expr == nullptr || !eat(")")) {
                setErr(PARSE_ERR);
                return nullptr;
            }
            n->lets.push_back(p);
        }
        if (!eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        n->a = parseExpr();
        if (err != NO_ERR || n->a == nullptr || !eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        return n;
    }

    if (head == "lambda") {
        posi++;
        Node* n = newNode();
        n->kind = N_LAMBDA;
        if (!eat("(")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        while (!done() && nowTok() != ")") {
            if (!goodName(nowTok())) {
                setErr(PARSE_ERR);
                return nullptr;
            }
            n->names.push_back(nowTok());
            posi++;
        }
        if (!eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        n->a = parseExpr();
        if (err != NO_ERR || n->a == nullptr || !eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        return n;
    }

    if (head == "define") {
        posi++;
        Node* n = newNode();
        n->kind = N_DEFINE;
        if (done() || !goodName(nowTok())) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        n->word = nowTok();
        posi++;
        n->a = parseExpr();
        if (err != NO_ERR || n->a == nullptr || !eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        return n;
    }

    if (head == "cond") {
        posi++;
        Node* n = newNode();
        n->kind = N_COND;
        bool sawElse = false;
        while (!done() && nowTok() != ")") {
            if (!eat("(")) {
                setErr(PARSE_ERR);
                return nullptr;
            }
            CondPart cp;
            cp.isElse = false;
            cp.test = nullptr;
            cp.answer = nullptr;

            if (nowTok() == "else") {
                if (sawElse) {
                    setErr(PARSE_ERR);
                    return nullptr;
                }
                sawElse = true;
                cp.isElse = true;
                posi++;
                cp.answer = parseExpr();
                if (err != NO_ERR || cp.answer == nullptr || !eat(")")) {
                    setErr(PARSE_ERR);
                    return nullptr;
                }
            } else {
                cp.test = parseExpr();
                cp.answer = parseExpr();
                if (err != NO_ERR || cp.test == nullptr || cp.answer == nullptr || !eat(")")) {
                    setErr(PARSE_ERR);
                    return nullptr;
                }
            }
            n->conds.push_back(cp);
        }
        if (n->conds.empty() || !eat(")")) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        return n;
    }

    Node* n = newNode();
    n->kind = N_CALL;
    n->a = parseExpr();
    if (err != NO_ERR || n->a == nullptr) {
        setErr(PARSE_ERR);
        return nullptr;
    }
    while (!done() && nowTok() != ")") {
        Node* x = parseExpr();
        if (err != NO_ERR || x == nullptr) {
            setErr(PARSE_ERR);
            return nullptr;
        }
        n->list.push_back(x);
    }
    if (!eat(")")) {
        setErr(PARSE_ERR);
        return nullptr;
    }
    return n;
}

Node* parseExpr() {
    if (done()) {
        setErr(PARSE_ERR);
        return nullptr;
    }

    string t = nowTok();
    if (t == "(") return parseList();

    posi++;
    Node* n = newNode();
    if (isIntTok(t)) {
        n->kind = N_INT;
        n->num = stoi(t);
        return n;
    }
    if (isBoolTok(t)) {
        n->kind = N_BOOL;
        n->tf = (t == "#t");
        return n;
    }
    if (t == ")") {
        setErr(PARSE_ERR);
        return nullptr;
    }
    n->kind = N_ID;
    n->word = t;
    return n;
}

vector<Node*> parseProgram(const string& text) {
    //toks is a variable that all functions have access to, is a vector<string>
    toks = splitTokens(text);
    posi = 0;
    vector<Node*> prog;
    while (!done() && err == NO_ERR) {
        Node* n = parseExpr();
        if (err != NO_ERR || n == nullptr) {
            setErr(PARSE_ERR);
            break;
        }
        prog.push_back(n);
    }
    if (err == NO_ERR && posi != toks.size()) setErr(PARSE_ERR);
    return prog;
}

void addBuiltin(Env* e, const string& s) {
    Func* f = newFunc();
    f->builtin = true;
    f->op = s;
    e->table[s] = makeFuncVal(f);
}

Val eval(Node* n, Env* e);

Val runBuiltin(Func* f, const vector<Val>& args) {
    string op = f->op;

    if (op == "+") {
        int sum = 0;
        for (auto v : args) {
            if (!needInt(v)) return Val();
            sum += v.num;
        }
        return makeInt(sum);
    }

    if (op == "-") {
        if (args.empty()) {
            setErr(ARITY_ERR);
            return Val();
        }
        if (!needInt(args[0])) return Val();
        int ans = args[0].num;
        if (args.size() == 1) return makeInt(-ans);
        for (int i = 1; i < (int)args.size(); i++) {
            if (!needInt(args[i])) return Val();
            ans -= args[i].num;
        }
        return makeInt(ans);
    }

    if (op == "*") {
        int ans = 1;
        for (auto v : args) {
            if (!needInt(v)) return Val();
            ans *= v.num;
        }
        return makeInt(ans);
    }

    if (op == "/") {
        if (args.empty()) {
            setErr(ARITY_ERR);
            return Val();
        }
        if (!needInt(args[0])) return Val();
        int ans = args[0].num;
        if (args.size() == 1) {
            if (ans == 0) {
                setErr(DIV_ZERO_ERR);
                return Val();
            }
            return makeInt(1 / ans);
        }
        for (int i = 1; i < (int)args.size(); i++) {
            if (!needInt(args[i])) return Val();
            if (args[i].num == 0) {
                setErr(DIV_ZERO_ERR);
                return Val();
            }
            ans /= args[i].num;
        }
        return makeInt(ans);
    }

    if (op == "=" || op == "<" || op == ">" || op == "<=" || op == ">=") {
        if (args.size() != 2) {
            setErr(ARITY_ERR);
            return Val();
        }
        if (!needInt(args[0]) || !needInt(args[1])) return Val();
        bool ok = false;
        if (op == "=") ok = args[0].num == args[1].num;
        if (op == "<") ok = args[0].num < args[1].num;
        if (op == ">") ok = args[0].num > args[1].num;
        if (op == "<=") ok = args[0].num <= args[1].num;
        if (op == ">=") ok = args[0].num >= args[1].num;
        return makeBool(ok);
    }

    setErr(UNDECLARED_ERR);
    return Val();
}

Val runFunc(const Val& fv, const vector<Val>& args) {
    if (fv.type != FUNC_VAL || fv.fn == nullptr) {
        setErr(TYPE_ERR);
        return Val();
    }

    Func* f = fv.fn;
    if (f->builtin) return runBuiltin(f, args);

    if (args.size() != f->params.size()) {
        setErr(ARITY_ERR);
        return Val();
    }

    Env* local = newEnv(f->saved);
    for (int i = 0; i < (int)f->params.size(); i++) {
        local->table[f->params[i]] = args[i];
    }
    return eval(f->body, local);
}

Val eval(Node* n, Env* e) {
    if (err != NO_ERR || n == nullptr) return Val();

    if (n->kind == N_INT) return makeInt(n->num);
    if (n->kind == N_BOOL) return makeBool(n->tf);

    if (n->kind == N_ID) {
        Val out;
        if (!findVar(e, n->word, out)) {
            setErr(UNDECLARED_ERR);
            return Val();
        }
        return out;
    }

    if (n->kind == N_IF) {
        Val test = eval(n->a, e);
        if (err != NO_ERR) return Val();
        if (!needBool(test)) return Val();
        if (test.tf) return eval(n->b, e);
        return eval(n->c, e);
    }

    if (n->kind == N_LET) {
        Env* local = newEnv(e);
        for (auto p : n->lets) {
            Val v = eval(p.expr, e);
            if (err != NO_ERR) return Val();
            local->table[p.name] = v;
        }
        return eval(n->a, local);
    }

    if (n->kind == N_LAMBDA) {
        Func* f = newFunc();
        f->builtin = false;
        f->params = n->names;
        f->body = n->a;
        f->saved = e;
        return makeFuncVal(f);
    }

    if (n->kind == N_CALL) {
        Val who = eval(n->a, e);
        if (err != NO_ERR) return Val();
        vector<Val> vals;
        for (auto part : n->list) {
            Val v = eval(part, e);
            if (err != NO_ERR) return Val();
            vals.push_back(v);
        }
        return runFunc(who, vals);
    }

    if (n->kind == N_DEFINE) {
        if (n->a != nullptr && n->a->kind == N_LAMBDA) {
            Func* f = newFunc();
            f->builtin = false;
            f->params = n->a->names;
            f->body = n->a->a;
            f->saved = e;
            e->table[n->word] = makeFuncVal(f);
            return e->table[n->word];
        }
        Val v = eval(n->a, e);
        if (err != NO_ERR) return Val();
        e->table[n->word] = v;
        return v;
    }

    if (n->kind == N_COND) {
        for (auto part : n->conds) {
            if (part.isElse) return eval(part.answer, e);
            Val test = eval(part.test, e);
            if (err != NO_ERR) return Val();
            if (!needBool(test)) return Val();
            if (test.tf) return eval(part.answer, e);
        }
        setErr(TYPE_ERR);
        return Val();
    }

    setErr(PARSE_ERR);
    return Val();
}

string readAll(const string& fileName) {
    ifstream in(fileName);
    if (!in) {
        //setErr is a funtion that takes errType values which I stablished at the beggining 
        setErr(PARSE_ERR);
        return "";
    }
    stringstream ss;
    ss << in.rdbuf(); //read everything on the file 
    return ss.str(); 
}

Env* startEnv() {
    Env* e = newEnv(nullptr);
    addBuiltin(e, "+");
    addBuiltin(e, "-");
    addBuiltin(e, "*");
    addBuiltin(e, "/");
    addBuiltin(e, "=");
    addBuiltin(e, "<");
    addBuiltin(e, ">");
    addBuiltin(e, "<=");
    addBuiltin(e, ">=");
    return e;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        cerr << "Usage: " << argv[0] << " <file>\n";
        return 1;
    }

    //this is for reading from the files 
    string text = readAll(argv[1]); 
    vector<Node*> prog;
    Val last;

    if (err == NO_ERR) prog = parseProgram(text);

    if (err == NO_ERR) {
        Env* global = startEnv();
        for (auto x : prog) {
            last = eval(x, global);
            if (err != NO_ERR) break;
        }
    }

    if (err != NO_ERR) {
        cout << "Status: ERROR\n";
        cout << "Error: " << errName(err) << "\n";
        return 0;
    }

    cout << "Status: OK\n";
    cout << "Result: " << showVal(last) << "\n";
    cout << "Type: " << typeName(last.type) << "\n";
    return 0;
}
