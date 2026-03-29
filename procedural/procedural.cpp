/*this code can already read and and parse a simple expression such as (+ 2 5) 
*/
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

//global variables to store numbers
vector<int> numbers; 


// Function declarations
void operation(int op);
void parseFile(const string& filename);


int main(int argc, char* argv[]) {
    if(argc != 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }
    string filename = argv[1];
    parseFile(filename);


    return 0;
}

void perform_operation(int op) {
    switch (op){
    case 1: {// Addition
        int right = numbers.back();
        numbers.pop_back();
        int left = numbers.back();
        numbers.pop_back();
        numbers.push_back(left + right);
        numbers.push_back(left + right); // Agrega el resultado al vector
        cout << "Result of addition: " << left + right << endl;
        break;
    }
    
    default:
        break;
    }
}

void parseFile(const string& filename) {
    ifstream file;
    string word;
    
    int operation = 0; // 0 for none, 1 for addition...
    file.open(filename);
    if(!file.is_open()) {
        cerr << "Error opening file: " << filename << endl;
        return;
    }
    while(file >> word) {
        // Procesa palabra por palabra
        if(word.find('(') != string::npos) {
            size_t position = word.find('(');
            word = word.erase(position, 1); // Elimina el paréntesis
        }else if(word.find(')') != string::npos){
            size_t position = word.find(')');
            word = word.erase(position, 1); // Elimina el paréntesis
        } 
        
        if(word == "+") {
            char aux = word[0];
            switch (aux){
            case '+':
                operation = 1;
                break;
            
            default:
                cerr << "Invalid operation: " << aux << endl; // Maneja el error de operación no válida
                break;
            }
        }else{
        

            try {
                int number = stoi(word); // Convierte la palabra a número
                numbers.push_back(number); // Agrega el número al vector
            } catch (const invalid_argument& e) {
                cerr << "Invalid number: " << word << endl; // Maneja el error de conversión
            }
        }
    }

    perform_operation(operation);

    file.close();
}
