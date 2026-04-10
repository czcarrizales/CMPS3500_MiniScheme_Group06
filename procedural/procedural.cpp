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
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
        //argv[1] = "bool_03.scm";
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

}

void get_parenthesis(){
    int aux = 0; // counter for index
    open_parenthesis.clear();
    close_parenthesis.clear();
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
            cout << expression.find('t') << endl;
            cout << expression.find('f') << endl;
            if(expression.find('f') != string::npos){
                expression = "False";
            }else if(expression.find('t') != string::npos){
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
            if(s.find("if") != string::npos){
                string if_return;
                values >> if_return; // discard the "if" statement
                values >> if_return;
                if(if_return == "#t"){
                    values >> if_return;
                    expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, if_return);
                }else if(if_return == "#f"){
                    values >> if_return; // discard value for true 
                    values >> if_return;
                    expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, if_return);
                }
                get_parenthesis();

            }


            char sign;
            int result = 0; 
            values >> sign;
            string aux; 

            switch(sign){
                case '+':{
                    while (values >>  aux){
                        result += stoi(aux);
                    }
                    expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, to_string(result));
                    break;
                }

                case '-':{
                    while (values >>  aux){
                        result -= stoi(aux);
                    }
                    expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, to_string(result));
                    break;
                }

                case '*':{
                    result = 1;
                    while (values >>  aux){
                        result *= stoi(aux);
                    }
                    expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, to_string(result));
                    break;
                }

//need to verify the division by 0
                case '/':{
                    while (values >>  aux){
                        result /= stoi(aux);
                    }
                    expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, to_string(result));
                    break;
                }

//I feel like I will need to change something
                case '<':{
                    int k, j;
                    values >> j;
                    values >> k;
                    
                    if(j < k){
                        expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, "#t");
                    }else{
                        expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, "#f");
                    }
                    
                    break;
                    
                }

                //I feel like I will need to change something
                case '>':{
                    int k, j;
                    values >> j;
                    values >> k;
                    
                    if(j > k){
                        expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, "#t");
                    }else{
                        expression.replace(open_parenthesis[i], close_parenthesis[0] - open_parenthesis[i] + 1, "#f");
                    }
                    
                }
                break;

                default: 
                    cerr << "INVALID_SIGN" << endl;
                    break; 
            } //switch
            
            get_parenthesis();
        }//if
    }// for
    operation();
}//function

