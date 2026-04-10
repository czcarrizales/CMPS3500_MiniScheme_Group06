#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>

using namespace std;

//global variables to store numbers
vector<int> numbers; 
vector <size_t> open_parenthesis;
vector<size_t> close_parenthesis;
string expression;



// Function declarations
void operation();
void parseFile(const string& filename);
void get_parenthesis();


int main(int argc, char* argv[]) {
    if(argc != 2) {
        //cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        //return 1;
        argv[1] = "core_02.scm";
    }
    
    parseFile(argv[1]);
    
    


    return 0;
}

void parseFile(const string& name_of_file){
    ifstream file(name_of_file);
    if(!file){
        cerr << "FILE_NOT_FOUND" << endl;
    }
    
    while(getline(file, expression)){
        get_parenthesis();
        operation();
    }
    file.close();
}

void get_parenthesis(){
    int aux = 0; // counter for index
        for(char c : expression){
            if(c == '('){
                open_parenthesis.push_back(aux);
                aux++;
            }else if(c == ')'){
                close_parenthesis.push_back(aux);
                aux++;
            }else{aux++;}
        }

    if(open_parenthesis.size() == 0 || close_parenthesis.size() == 0){
        if(expression.find('#') != string::npos && expression.size() == 2){
            if(expression.find('F') || expression.find('f')){
                expression = "False";
            }else if(expression.find('T') || expression.find('t')){
                expression = "True";
            }else{
                cerr << "INVALID_INPUT" << endl;
            }

        }
        cout << "the result is: " << expression << endl;
        exit(0);
    }
}

void operation(){
    for(int i = open_parenthesis.size() - 1; i >= 0; i--){
        if(open_parenthesis[i] < close_parenthesis[0]){
            string s = expression.substr(open_parenthesis[i] + 1, close_parenthesis[0] - (open_parenthesis[i] + 1));
            stringstream values(s);
            char sign;
            int result = 0; 
            values >> sign;
            string aux; 

            switch(sign){
                case '+':{
                    while (values >>  aux){
                        result += stoi(aux);
                    }
                    break;
                }

                case '-':{
                    while (values >>  aux){
                        result -= stoi(aux);
                    }
                    break;
                }

                case '*':{
                    result = 1;
                    while (values >>  aux){
                        result *= stoi(aux);
                    }
                    break;
                }

//need to verify the division by 0
                case '/':{
                    while (values >>  aux){
                        result /= stoi(aux);
                    }
                    break;
                }

//I feel like I will need to change something
                case '<':{
                    int i, j;
                    values >> i;
                    values >> j;
                    
                    if(i < j){
                        expression = "True";
                    }else{
                        expression = "False";
                    }
                    cout << "the result is: " << expression << endl;
                    exit(0);
                }

                //I feel like I will need to change something
                case '>':{
                    int i, j;
                    values >> i;
                    values >> j;
                    
                    if(i > j){
                        expression = "True";
                    }else{
                        expression = "False";
                    }
                    cout << "the result is: " << expression << endl;
                    exit(0);
                }

                default: 
                    cerr << "INVALID_SIGN" << endl;
                    break; 
            } //switch
            expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, to_string(result));
            open_parenthesis.clear();
            close_parenthesis.clear();
            get_parenthesis();
        }//if
    }// for
    operation();
}//function
