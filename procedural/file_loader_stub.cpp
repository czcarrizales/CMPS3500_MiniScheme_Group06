// Tiny file-loading helper stub for the procedural implementation.
// Replace or adapt as needed.
#include <fstream>
#include <sstream>
#include <string>

std::string read_file(const std::string& path) {
    std::ifstream in(path);
    std::ostringstream ss;
    ss << in.rdbuf();
    return ss.str();
}
