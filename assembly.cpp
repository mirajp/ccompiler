#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

int fncallCount;
int argCount;
vector<string> globalstrings;
vector<string> code;

string stringToLC(string linein) {
    // handle string variables
    size_t start, end;
    start = linein.find("\"");
    if (start != string::npos) {
        end = linein.find("\"", start+1);
        if (end != string::npos) {
            stringstream number;
            string newGlobalStr = "$.LC";
            number << globalstrings.size();
            newGlobalStr += number.str();
            globalstrings.push_back(linein.substr(start, end));
            linein.replace(start, end, newGlobalStr);
        }
    }
    return linein;
}

string tempregLocation(string tempregister) {
    int end = tempregister.find(" =");
    if (end == string::npos) {
        //cout << "Setting to end of string" << endl;
        end = tempregister.length();
    }
    int start = tempregister.find("%T")+2;
    stringstream offset(tempregister.substr(start, end - start));
    //cout << "offset = " << offset.str() << endl;
    int tempNum = 0;
    offset >> tempNum;
    stringstream offsetMem;
    offsetMem << ((tempNum)*(-4));
    return (offsetMem.str()+"(%ebp)");
}

void process(istream &in) {
    string lineread;
    size_t start, end;
    
    while(getline(in, lineread)) {
        code.push_back("# " + lineread);
        //cout << "LINE READ: " << lineread << endl;
        
        lineread = stringToLC(lineread);
        
        if (lineread.find("ARGBEGIN") != string::npos) {
            int numArgs = 0;
            int offsetNum = 0;
            stringstream number(lineread.substr(lineread.find(" ", lineread.find("ARGBEGIN"))+1, lineread.length()-1-(lineread.find(" ", lineread.find("ARGBEGIN")))));
            number >> numArgs;
            ostringstream allocsize;
            allocsize << ((numArgs+1)*4);
            code.push_back("\tsubl $" + allocsize.str() + ", %esp\n");
            for (int i = argCount; i < numArgs + argCount; i++) {
                stringstream argoffset;
                getline(in, lineread);
                code.push_back("# " + lineread);
                lineread = stringToLC(lineread);
                string argument = lineread.substr(lineread.find(" ", lineread.find("ARG"))+1, lineread.length()-(lineread.find(" ", lineread.find("ARG")))-1);
                if (argument.find("%T") != string::npos) {
                    argument = tempregLocation(argument);
                }
                
                argoffset << i*4;
                code.push_back("\tmovl " + argument + ", %eax");
                code.push_back("\tmovl %eax, " + argoffset.str() + "(%esp)\n");
            }
            
            argCount += numArgs;
        }
        
        // If it contains a ':' and is not prefixed with a period, means function label
        else if (lineread[lineread.length()-1] == ':' && lineread[0] != '.') {
            code.push_back(".text");
            code.push_back(".global " + lineread.substr(0, lineread.length()-1));
            code.push_back("");
            code.push_back(lineread);
            code.push_back("\tpushl %ebp");
            code.push_back("\tmovl %esp, %ebp\n");
        }

        else if (lineread.find("RETURN") != string::npos) {
            string returnVal = lineread.substr(lineread.find(" ", lineread.find("RETURN"))+1, lineread.length()-1-(lineread.find(" ", lineread.find("RETURN"))));
            if (returnVal.length() > 0) {
                code.push_back("\tmovl " + returnVal + ", %eax");
            }
            code.push_back("\tleave");
            code.push_back("\tret");
        }
        
        else if (lineread.find("CALL") != string::npos) {
            
            // Read in the CALL function line - no support at the moment for storing return values
            //getline(in, lineread);
            //code.push_back("\n# " + lineread);
            string fnCall = lineread.substr(lineread.find(" ", lineread.find("CALL"))+1, lineread.length()-(lineread.find(" ", lineread.find("CALL")))-1);
            code.push_back("\tcall " + fnCall);
            
            /*
            int start = lineread.find("%T")+2;
            int end = lineread.find(" =");
            stringstream offset(lineread.substr(start, end - start));
            offset >> offsetNum;
            stringstream offsetMem;
            offsetMem << ((offsetNum)*(-4));
            */
            
            stringstream offsetMem(tempregLocation(lineread));
            code.push_back("\tmovl %eax, " + offsetMem.str() + "\n");
        }
        
        else if (lineread.find("MOV") != string::npos) {
            string argument = lineread.substr(lineread.find(" ", lineread.find("MOV"))+1, lineread.length()-(lineread.find(" ", lineread.find("MOV")))-1);
            if (argument.find("%T") != string::npos) {
                argument = tempregLocation(argument);
            }
            
            string destination = lineread.substr(1, lineread.find("=")-2);
            if (destination.find("%T") != string::npos) {
                destination = tempregLocation(destination);
            }
            //cout << "Destination = " << destination << "." << endl;
            //cout << "Value = " << argument << "." << endl;
            code.push_back("\tmovl " + argument + ", %eax");
            code.push_back("\tmovl %eax, " + destination + "\n");
        }
        
        else if (lineread.find("ADD") != string::npos) {
            int start = lineread.find(" ", lineread.find("ADD"))+1;
            int end = lineread.find(",");
            string argumentA = lineread.substr(start, end-start);
            start = end+2;
            end = lineread.length();
            string argumentB = lineread.substr(start, end-start);
            string destination = lineread.substr(1, lineread.find("=")-2);
            //cout << "ArgA = " << argumentA << ", ArgB = " << argumentB << "." << endl;
            if (destination.find("%T") != string::npos) {
                destination = tempregLocation(destination);
            }
            if (argumentA.find("%T") != string::npos) {
                argumentA = tempregLocation(argumentA);
            }
            if (argumentB.find("%T") != string::npos) {
                argumentB = tempregLocation(argumentB);
            }
            
            
            //cout << "Destination = " << destination << "." << endl;
            
            //# %T18 = ADD %T17,%T19
            code.push_back("\tmovl " + argumentA + ", %eax");
            code.push_back("\tmovl " + argumentB + ", %edx");
            code.push_back("\taddl %eax, %edx");
            code.push_back("\tmovl %edx, " + destination + "\n");
            
        }
        
        else if (lineread.find("SUB") != string::npos) {
            
        }
        
        else if (lineread.find("MUL") != string::npos) {
        }
        
        else if (lineread.find("DIV") != string::npos) {
            
        }
    }
    
}

void printassembly() {
    cout << ".data" << endl;
    for (int i = 0; i < globalstrings.size(); i++) {
        cout << ".LC" << i << ":" << endl;
        cout << "\t.string " << globalstrings[i] << endl;
    }
    
    for (int i = 0; i < code.size(); i++) {
        cout << code[i] << endl;
    }
}


int main(int argc, char *argv[]) {
    ifstream input;
    if (argc > 3) {
        cerr << "Error: Expected usage: ./" << argv[0] << " [quadsfile ]" << endl;
        return 1;
    }
    else if (argc == 2) {
        input.open(argv[1]);
        process(input);
        input.close();
    }
    else {
        process(cin);
    }
    
    printassembly();
}

