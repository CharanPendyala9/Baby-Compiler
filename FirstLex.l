%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
enum	{LEFTPAR=1,RIGHTPAR,COMMA,COMMENT,
			REG=10,REGIND,IDENTIFIER,INTCONST,FLOATCONST,LABELDEF,LABEL,
			REGMODE=20,DIRECTMODE,INDIRECTMODE,IMMEDIATEMODE,
			ALLOC=50,READ,WRITE,LOAD,LOADA,STORE,MOVE,ADD,SUB,MUL,DIV,MOD,CMP,B,BLT,BLE,BNE,BEQ,BGE,BGT,
			UNRESOLVED=100,RESOLVED,
			VAR=110,
			GREATERTHAN=115,EQUAL,LESSTHAN,
			ERROR=143};

//--------------------------- MAP DEFINITION ----------------------//
struct token
{
     int ref;
		 char val[30];
};

struct Line
{
     struct token tokens[200];
};

struct Line Lines[65536];

int LineNum = 0;
int LineIndex = 0;
//---------------------------- MAP DEFINITION END ----------------//

int free_Mem = 0;
int ST_Index = 0;
int PC=1;

struct instr {
		unsigned char opcode;
		unsigned char addr_mode:5;
		unsigned char reg_no:3;

		union{
			short immed_val;
			unsigned short address;
		}u;

};
typedef struct instr INSTR;

struct stdr{
	char key[500];
	int tag;
	unsigned short value;
	struct stdr *next;
};

typedef struct stdr ST_DATAREC;

//------------- PArray --------- Program Array ------------------//
INSTR PArray[65536];

//-------------- MArray --------- Main Memory Array -------------//
long int MArray[65536];

//-------------- RegArray -------- Register Array ---------------//
long int RegArray[8];

//-------------- STArray --------- Symbol Table Array -----------//
ST_DATAREC STArray[65536];

int err_flag = 0;
int last_cmp = 0;
%}

digit							[0-9]
reg								[r][0-7]
IntegerConstant 	{digit}+
Identifier 			  [a-zA-Z_]+({IntegerConstant})?
labeldef 					[$][a-zA-Z_0-9]+[:]
label 						[$][a-zA-Z_0-9]+
comment 					[#][^\n]*[\n]
inlinecomment			[ \t]+({comment})
floatConst				([0-9]+)?[.][0-9]+([eE][-+]?[0-9]+)?
%%

[ \t]+	  				{/*fprintf(stderr,"%s : white space \n", yytext);*/}
[\n]+							{LineIndex=0; LineNum++;}
[(]								{Lines[LineNum].tokens[LineIndex].ref=LEFTPAR;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
[)]								{Lines[LineNum].tokens[LineIndex].ref=RIGHTPAR;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
[,]								{Lines[LineNum].tokens[LineIndex].ref=COMMA;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
{comment}					{}
{inlinecomment}		{LineIndex=0; LineNum++;}
{IntegerConstant} {Lines[LineNum].tokens[LineIndex].ref=INTCONST;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;	/*int val; val = atoi(yytext); fprintf(stderr,"%s : is an integer constant, converted to integer and incremented to %d\n", yytext,++val);*/}
{floatConst}			{/*float val; val = atof(yytext)+1; fprintf(stderr,"%s : is a float constant, converted to float and incremented to %g\n", yytext,val);*/}
.alloc						{Lines[LineNum].tokens[LineIndex].ref=ALLOC;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
load							{Lines[LineNum].tokens[LineIndex].ref=LOAD;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
loada							{Lines[LineNum].tokens[LineIndex].ref=LOADA;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
store							{Lines[LineNum].tokens[LineIndex].ref=STORE;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
move							{Lines[LineNum].tokens[LineIndex].ref=MOVE;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
add								{Lines[LineNum].tokens[LineIndex].ref=ADD;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
sub								{Lines[LineNum].tokens[LineIndex].ref=SUB;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
mul 							{Lines[LineNum].tokens[LineIndex].ref=MUL;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
div								{Lines[LineNum].tokens[LineIndex].ref=DIV;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
mod								{Lines[LineNum].tokens[LineIndex].ref=MOD;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
cmp								{Lines[LineNum].tokens[LineIndex].ref=CMP;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
b									{Lines[LineNum].tokens[LineIndex].ref=B;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
blt								{Lines[LineNum].tokens[LineIndex].ref=BLT;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
ble 							{Lines[LineNum].tokens[LineIndex].ref=BLE;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
bne								{Lines[LineNum].tokens[LineIndex].ref=BNE;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
beq								{Lines[LineNum].tokens[LineIndex].ref=BEQ;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
bge								{Lines[LineNum].tokens[LineIndex].ref=BGE;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
bgt								{Lines[LineNum].tokens[LineIndex].ref=BGT;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
{reg}							{Lines[LineNum].tokens[LineIndex].ref=REG;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
[(]{reg}[)]				{Lines[LineNum].tokens[LineIndex].ref=REGIND;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
write							{Lines[LineNum].tokens[LineIndex].ref=WRITE;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
read							{Lines[LineNum].tokens[LineIndex].ref=READ;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
{label}						{Lines[LineNum].tokens[LineIndex].ref=LABEL;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
{labeldef}				{Lines[LineNum].tokens[LineIndex].ref=LABELDEF;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
{Identifier}			{Lines[LineNum].tokens[LineIndex].ref=IDENTIFIER;strncpy(Lines[LineNum].tokens[LineIndex].val,yytext,yyleng);LineIndex++;}
.|\n							{fprintf(stderr,"%s :Undefined character found\n", yytext);}
%%

int execute()
{
	int _pc=1;
		while(_pc<=PC)
		{
			if(PArray[_pc].opcode == READ)
			{
				scanf("%ld",&RegArray[PArray[_pc].reg_no]);
			}

			if(PArray[_pc].opcode == WRITE)
			{
				printf("%ld\n",RegArray[PArray[_pc].reg_no]);
			}

			if(PArray[_pc].opcode == LOAD)
			{
				if(PArray[_pc].addr_mode == DIRECTMODE)
				{
					RegArray[PArray[_pc].reg_no] = MArray[PArray[_pc].u.address];
				}
				else if(PArray[_pc].addr_mode == INDIRECTMODE)
				{
					RegArray[PArray[_pc].reg_no] = MArray[RegArray[PArray[_pc].u.address]];
				}
			}

			if(PArray[_pc].opcode == LOADA)
			{
				if(PArray[_pc].addr_mode == DIRECTMODE)
				{
					RegArray[PArray[_pc].reg_no] = PArray[_pc].u.address;
				}
				else if(PArray[_pc].addr_mode == INDIRECTMODE)
				{
					RegArray[PArray[_pc].reg_no] = MArray[RegArray[PArray[_pc].u.address]];
				}
			}

			if(PArray[_pc].opcode == STORE)
			{
				if(PArray[_pc].addr_mode == DIRECTMODE)
				{
					MArray[PArray[_pc].u.address] = RegArray[PArray[_pc].reg_no];
				}
				else if(PArray[_pc].addr_mode == INDIRECTMODE)
				{
					MArray[RegArray[PArray[_pc].u.address]] = RegArray[PArray[_pc].reg_no];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					MArray[PArray[_pc].u.immed_val] = RegArray[PArray[_pc].reg_no];
				}
			}

			if(PArray[_pc].opcode == MOVE)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					RegArray[PArray[_pc].reg_no] = RegArray[PArray[_pc].u.immed_val];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					RegArray[PArray[_pc].reg_no] = PArray[_pc].u.immed_val;
				}
			}

			if(PArray[_pc].opcode == ADD)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					RegArray[PArray[_pc].reg_no] += RegArray[PArray[_pc].u.immed_val];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					RegArray[PArray[_pc].reg_no] += PArray[_pc].u.immed_val;
				}
			}

			if(PArray[_pc].opcode == SUB)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					RegArray[PArray[_pc].reg_no] -= RegArray[PArray[_pc].u.immed_val];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					RegArray[PArray[_pc].reg_no] -= PArray[_pc].u.immed_val;
				}
			}

			if(PArray[_pc].opcode == MUL)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					RegArray[PArray[_pc].reg_no] *= RegArray[PArray[_pc].u.immed_val];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					RegArray[PArray[_pc].reg_no] *= PArray[_pc].u.immed_val;
				}
			}

			if(PArray[_pc].opcode == DIV)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					RegArray[PArray[_pc].reg_no] /= RegArray[PArray[_pc].u.immed_val];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					RegArray[PArray[_pc].reg_no] /= PArray[_pc].u.immed_val;
				}
			}

			if(PArray[_pc].opcode == MOD)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					RegArray[PArray[_pc].reg_no] %= RegArray[PArray[_pc].u.immed_val];
				}
				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					RegArray[PArray[_pc].reg_no] %= PArray[_pc].u.immed_val;
				}
			}

			if(PArray[_pc].opcode == CMP)
			{
				if(PArray[_pc].addr_mode == REGMODE)
				{
					if(RegArray[PArray[_pc].reg_no] < RegArray[PArray[_pc].u.immed_val])
					{
						last_cmp = LESSTHAN;
					}

					else if(RegArray[PArray[_pc].reg_no] > RegArray[PArray[_pc].u.immed_val])
					{
						last_cmp = GREATERTHAN;
					}

					else if(RegArray[PArray[_pc].reg_no] == RegArray[PArray[_pc].u.immed_val])
					{
						last_cmp = EQUAL;
					}
				}

				else if(PArray[_pc].addr_mode == IMMEDIATEMODE)
				{
					if(RegArray[PArray[_pc].reg_no] < PArray[_pc].u.immed_val)
					{
						last_cmp = LESSTHAN;
					}

					else if(RegArray[PArray[_pc].reg_no] > PArray[_pc].u.immed_val)
					{
						last_cmp = GREATERTHAN;
					}

					else if(RegArray[PArray[_pc].reg_no] == PArray[_pc].u.immed_val)
					{
						last_cmp = EQUAL;
					}
				}
			}

			if(PArray[_pc].opcode == B)
			{
				_pc= PArray[_pc].u.address;
				continue;
			}

			if(PArray[_pc].opcode == BLT)
			{
				if(last_cmp == LESSTHAN)
				{
					_pc= PArray[_pc].u.address;
					continue;
				}
			}

			if(PArray[_pc].opcode == BGT)
			{
				if(last_cmp == GREATERTHAN)
				{
					_pc= PArray[_pc].u.address;
					continue;
				}
			}

			if(PArray[_pc].opcode == BLE)
			{
				if((last_cmp == LESSTHAN) || (last_cmp == EQUAL))
				{
					_pc= PArray[_pc].u.address;
					continue;
				}
			}

			if(PArray[_pc].opcode == BGE)
			{
				if((last_cmp == GREATERTHAN) || (last_cmp == EQUAL))
				{
					_pc= PArray[_pc].u.address;
					continue;
				}
			}

			if(PArray[_pc].opcode == BNE)
			{
				if(last_cmp != EQUAL)
				{
					_pc= PArray[_pc].u.address;
					continue;
				}
			}

			if(PArray[_pc].opcode == BEQ)
			{
				if(last_cmp == EQUAL)
				{
					_pc= PArray[_pc].u.address;
					continue;
				}
			}

			_pc++;
		}
		return 0;
}

short getRegNum(char c[10])
{
	if((strcmp(c,"r0")==0)||(strcmp(c,"(r0)")==0))
	{
	 return 0;
	}
	if((strcmp(c,"r1")==0)||(strcmp(c,"(r1)")==0))
	{
		return 1;
	}
	if((strcmp(c,"r2")==0)||(strcmp(c,"(r2)")==0))
	{
		return 2;
	}
	if((strcmp(c,"r3")==0)||(strcmp(c,"(r3)")==0))
	{
		return 3;
	}
	if((strcmp(c,"r4")==0)||(strcmp(c,"(r4)")==0))
	{
		return 4;
	}
	if((strcmp(c,"r5")==0)||(strcmp(c,"(r5)")==0))
	{
		return 5;
	}
	if((strcmp(c,"r6")==0)||(strcmp(c,"(r6)")==0))
	{
		return 6;
	}
	if((strcmp(c,"r7")==0)||(strcmp(c,"(r7)")==0))
	{
		return 7;
	}
}

int getValFromST(char k[50])
{
	int i;
	for(i=0;i<ST_Index;i++)
	{
		if(strcmp(STArray[i].key,k)==0)
		{
			return STArray[i].value;
		}
	}
	return 65540;
}

int getIndexFromST(char k[50])
{
	int i;
	for(i=0;i<ST_Index;i++)
	{
		if(strcmp(STArray[i].key,k)==0)
		{
			return i;
		}
	}
	return 65540;
}

int main(int argc, char **argv)
{
int _tokenRef;
char _tokenVal[30];
int linNum;
int linIndex;

++argv, --argc;     /* skip over program name */
if ( argc > 0 )
      yyin = fopen( argv[0], "r" );
else
    	yyin = stdin;

	//FILE *ifp = fopen(argv,"r");
	//FILE *ofp = fopen("output.txt","w");

	//if(ifp == NULL)
	//	{
	//		printf("Input file not found\n");
	//	}

	//if(ofp == NULL)
	//	{
	//		printf("output file not found\n");
	//	}

	////yyin = ifp;
	//yyout = ofp;

//--------------------------- yylex called only once -----------------------
	yylex();
//--------------------------------------------------------------------------

	for(linNum=0;linNum<65536;linNum++)
	{
			linIndex=0;

			_tokenRef = Lines[linNum].tokens[linIndex].ref;
			strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);


			if(_tokenRef == 0)
			{
				break;
			}

			//-------------- HANDLE EVENTS FROM FIRST TOKEN OF LINES ------------//

			if(_tokenRef == ALLOC)
			{
				// Go to Next Token 2nd
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				//fprintf(stderr,"%d , %s\n",_tokenRef,_tokenVal);

				// If next token is identifier reserve allocation
				if(_tokenRef == IDENTIFIER)
				{
					strcpy(STArray[ST_Index].key,_tokenVal);
					STArray[ST_Index].tag = VAR;

					// Go to Next Token 3rd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					// If comma not identified and found int const alloc array size - increment
					// size of memory pointer free_mem by size required
					if(_tokenRef == INTCONST)
					{
						STArray[ST_Index].value = free_Mem;
						ST_Index++; // Increment ST index
						free_Mem += atoi(_tokenVal); 	// Might lead to overflow if > 65535
					}

					//Reserve one space of long int in MArray
					if(_tokenRef == 0)
					{
						STArray[ST_Index].value = free_Mem;
						free_Mem++;
						ST_Index++; // Increment ST index
					}

					if(_tokenRef == COMMA)
					{
						// next token 2nd arg
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref; // second argument
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val); // second argument

						if(_tokenRef == INTCONST)
						{
							STArray[ST_Index].value = free_Mem;
							free_Mem += atoi(_tokenVal);
							ST_Index++; // Increment ST index
						}

						else if( _tokenRef == 0)
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d size of Identifier for .alloc not specified\n",linNum);
						}
					}
				}

				//Throw error if .alloc is not associated with a identifier
				else if(_tokenRef == 0)
				{
					err_flag = ERROR;
					fprintf(stderr,"# %d Identifier for .alloc not specified\n",linNum);
				}

				//fprintf(stderr,"ALLOC case identified\n");
				//fprintf(stderr,"ST-Key - %s %d\n",STArray[ST_Index-1].key,ST_Index);
				//fprintf(stderr,"ST-tag - %d\n",STArray[ST_Index-1].tag);
				//fprintf(stderr,"ST-value - free_mem %d\n",STArray[ST_Index-1].value);
				//fprintf(stderr,"M-index - %d\n",free_Mem);

				continue;
			}

			if(_tokenRef == LOAD)
			{
					PArray[PC].opcode = LOAD;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;

									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;

				continue;

			}

			if(_tokenRef == LOADA)
			{
				PArray[PC].opcode = LOADA;
				//fprintf(stderr,"%s instruction identified\n",_tokenVal);

				// Go to Next Token 2nd
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == REG)
				{

					PArray[PC].reg_no = getRegNum(_tokenVal);

					// Go to Next Token 3rd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == COMMA)
					{
						// Go to Next Token 4th - 4th argument
					 linIndex++;
					 _tokenRef = Lines[linNum].tokens[linIndex].ref;
					 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == REG)
						{
							PArray[PC].addr_mode = REGMODE;
							PArray[PC].u.immed_val = getRegNum(_tokenVal);
						}

						if(_tokenRef == IDENTIFIER)
						{
							PArray[PC].addr_mode = DIRECTMODE;


							//------- Look for IDENTIFIER in symbol table ----------//
							if(getValFromST(_tokenVal)==65540)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
							}

							else
							{
								PArray[PC].u.address = getValFromST(_tokenVal);


							}

						}

						if(_tokenRef == REGIND)
						{
							PArray[PC].addr_mode = INDIRECTMODE;
							//fprintf(stderr,"--------------indirect mode\n");
							//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
							PArray[PC].u.address = getRegNum(_tokenVal);
						}

						if(_tokenRef == INTCONST)
						{
							PArray[PC].addr_mode = IMMEDIATEMODE;
							PArray[PC].u.immed_val = atoi(_tokenVal);
						}

						if(_tokenRef == 0)
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
						}
					}
					else
					{
						err_flag = ERROR;
						fprintf(stderr,"# %d error - comma not found\n",linNum);
					}
				}

			//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
			//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
			//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
			//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
			//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

			PC++;
			continue;
			}

			if(_tokenRef == STORE)
			{
					PArray[PC].opcode = STORE;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;
				continue;

			}

			if(_tokenRef == MOVE)
			{
					PArray[PC].opcode = MOVE;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;
				continue;
			}

			if(_tokenRef == ADD)
			{

					PArray[PC].opcode = ADD;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;
				continue;
			}

			if(_tokenRef == SUB)
			{

					PArray[PC].opcode = SUB;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);
									//fprintf(stderr,"# %d Identifier can be found at %d\n",linNum,getValFromST(_tokenVal));

								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;

				continue;
			}

			if(_tokenRef == MUL)
			{

					PArray[PC].opcode = MUL;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;

				continue;
			}

			if(_tokenRef == DIV)
			{

					PArray[PC].opcode = DIV;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);

								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;

				continue;
			}

			if(_tokenRef == MOD)
			{

					PArray[PC].opcode = MOD;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;

				continue;
			}

			if(_tokenRef == CMP)
			{

					PArray[PC].opcode = CMP;
					//fprintf(stderr,"%s instruction identified\n",_tokenVal);

					// Go to Next Token 2nd
					linIndex++;
					_tokenRef = Lines[linNum].tokens[linIndex].ref;
					strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

					if(_tokenRef == REG)
					{

						PArray[PC].reg_no = getRegNum(_tokenVal);

						// Go to Next Token 3rd
						linIndex++;
						_tokenRef = Lines[linNum].tokens[linIndex].ref;
						strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

						if(_tokenRef == COMMA)
						{
							// Go to Next Token 4th - 4th argument
						 linIndex++;
						 _tokenRef = Lines[linNum].tokens[linIndex].ref;
						 strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

							if(_tokenRef == REG)
							{
								PArray[PC].addr_mode = REGMODE;
								PArray[PC].u.immed_val = getRegNum(_tokenVal);
							}

							if(_tokenRef == IDENTIFIER)
							{
								PArray[PC].addr_mode = DIRECTMODE;


								//------- Look for IDENTIFIER in symbol table ----------//
								if(getValFromST(_tokenVal)==65540)
								{
									err_flag = ERROR;
									fprintf(stderr,"# %d Identifier not allocated and cannot be used\n",linNum);
								}

								else
								{
									err_flag = ERROR;
									PArray[PC].u.address = getValFromST(_tokenVal);


								}

							}

							if(_tokenRef == REGIND)
							{
								PArray[PC].addr_mode = INDIRECTMODE;
								//fprintf(stderr,"--------------indirect mode\n");
								//fprintf(stderr,"--------------2nd arg %s \n",_tokenVal);
								PArray[PC].u.address = getRegNum(_tokenVal);
							}

							if(_tokenRef == INTCONST)
							{
								PArray[PC].addr_mode = IMMEDIATEMODE;
								PArray[PC].u.immed_val = atoi(_tokenVal);
							}

							if(_tokenRef == 0)
							{
								err_flag = ERROR;
								fprintf(stderr,"# %d error - 2nd argument not given\n",linNum);
							}
						}
						else
						{
							err_flag = ERROR;
							fprintf(stderr,"# %d error - comma not found\n",linNum);
						}
					}

				//fprintf(stderr,"I-opcode - %d\n",PArray[PC].opcode);
				//fprintf(stderr,"reg_no - %d\n",PArray[PC].reg_no);
				//fprintf(stderr,"add_mode - %d\n",PArray[PC].addr_mode);
				//fprintf(stderr,"u.address - %d\n",PArray[PC].u.address);
				//fprintf(stderr,"u.imm_val - %d\n",PArray[PC].u.immed_val);

				PC++;

				continue;
			}

			//------------------- Branch Instructions ----------------------//
			if(_tokenRef == B)
			{
				PArray[PC].opcode = B;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"------------back patch reference added for %s ---------\n ST[ %d ] = %s , %d \n",_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;
						}
					}
				}

				//fprintf(stderr,"%s - B case identified\n",_tokenVal);

				PC++;

				continue;
			}

			if(_tokenRef == BLT)
			{
				PArray[PC].opcode = BLT;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"------------back patch reference added for %s ---------\n ST[ %d ] = %s , %d \n",_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;
						}
					}
				}

				//fprintf(stderr,"%s - BLT case identified\n",_tokenVal);

				PC++;

				continue;

			}

			if(_tokenRef == BLE)
			{
				PArray[PC].opcode = BLE;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"------------back patch reference added for %s ---------\n ST[ %d ] = %s , %d \n",_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;
						}
					}
				}

				//fprintf(stderr,"%s - BLE case identified\n",_tokenVal);

				PC++;

				continue;
			}

			if(_tokenRef == BNE)
			{
				PArray[PC].opcode = BNE;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"------------back patch reference added for %s ---------\n ST[ %d ] = %s , %d \n",_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;
						}
					}
				}

				//fprintf(stderr,"%s - BNE case identified\n",_tokenVal);

				PC++;

				continue;
			}

			if(_tokenRef == BEQ)
			{
				PArray[PC].opcode = BEQ;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"# %d ------------back patch reference added for %s --------- ST[ %d ] = %s , %d --> PC - %d\n",linNum,_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag,PC);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;

							//fprintf(stderr,"# %d %s - RESOLVED \n",linNum,_tokenVal);

						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;

							//fprintf(stderr,"# %d %s - UNRESOLVED and bckptch1\n",linNum,_tokenVal);
						}
					}
				}

				//fprintf(stderr,"%s - BEQ case identified\n",_tokenVal);

				PC++;

				continue;
			}

			if(_tokenRef == BGE)
			{
				PArray[PC].opcode = BGE;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"# %d ------------back patch reference added for %s --------- ST[ %d ] = %s , %d -- > PC - %d \n",linNum,_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag,PC);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;
						}

						//fprintf(stderr,"# %d ------------label already added to ST resolved or unresolved %s --------- ST[ %d ] = %s , %d -- > PC - %d \n",linNum,_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag,PC);

					}
				}

				//fprintf(stderr,"%s - BGE case identified\n",_tokenVal);

				PC++;

				continue;
			}

			if(_tokenRef == BGT)
			{
				PArray[PC].opcode = BGT;

				// Go to Next Token 2nd arg
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == LABEL)
				{
					//------- Look for IDENTIFIER in symbol table ----------//

					int i = getIndexFromST(_tokenVal);

					// ---------------- if not found -----------------------//
					if(i == 65540)
					{
						//---------------- Store in ST as UNRESOLVED ----------//
						strcpy(STArray[ST_Index].key,_tokenVal);
						STArray[ST_Index].tag = UNRESOLVED;
						STArray[ST_Index].value = PC;
						ST_Index++;

						PArray[PC].u.address = 0;

						//fprintf(stderr,"------------back patch reference added for %s ---------\n ST[ %d ] = %s , %d \n",_tokenVal,ST_Index-1,STArray[ST_Index-1].key,STArray[ST_Index-1].tag);
					}

					//--------------- If found ----------------//
					else
					{
						if(STArray[i].tag == RESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
						}

						//------------------- Back Patching -----------------------//
						if(STArray[i].tag == UNRESOLVED)
						{
							PArray[PC].u.address = STArray[i].value;
							STArray[i].value = PC;
						}
					}
				}

				//fprintf(stderr,"%s - BGT case identified\n",_tokenVal);

				PC++;

				continue;
			}
			//-------------------------------------------------------------//


			// NEW LABEL DEFINITION
			if(_tokenRef == LABELDEF)
			{
				int ln = strlen(_tokenVal)-1;

				char _labelName[ln];

				strncpy(_labelName,_tokenVal,ln);

				while(strlen(_labelName) > ln)
				{
					_labelName[ln]='\0';
				}

				int check = getIndexFromST(_labelName) ;

				// ------------ If not found in ST, Add label name to ST -------------------------
				if(check == 65540)
				{
					strcpy(STArray[ST_Index].key,_labelName);
					STArray[ST_Index].tag = RESOLVED;
					STArray[ST_Index].value = PC;
					ST_Index++;

					//fprintf(stderr,"# %d Label not found and added as resolved %s --> PC - %d\n",linNum,_labelName,PC);
				}

				// -------------- If Found in ST ----------------------------//
				else
				{
					if(STArray[check].tag == UNRESOLVED)
					{
						STArray[check].tag = RESOLVED;
						//------------ back patch ------------------//
						short temp =  STArray[check].value;
						STArray[check].value = PC;

						while(1)
						{
							short new_temp = temp;
							temp = PArray[new_temp].u.address;
							PArray[new_temp].u.address = PC;
							if(temp == 0)
							{
								break;
							}
						}

						//fprintf(stderr,"# %d back patch needed for label %s --> PC - %d\n",linNum,_labelName,PC);
					}

					else if(STArray[check].tag == RESOLVED)
					{
						err_flag = ERROR;
						fprintf(stderr,"# %d label already defined and cannot be defined again\n ST[ %d ] = %s , %d \n",linNum,check,STArray[check].key,STArray[check].tag);
					}
				}

				continue;
			}

			if(_tokenRef == READ)
			{
				PArray[PC].opcode = READ;
				//fprintf(stderr,"%s instruction identified\n",_tokenVal);

				// Go to Next Token 2nd
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == REG)
				{
					PArray[PC].reg_no = getRegNum(_tokenVal);
				}
				else
				{
					err_flag = ERROR;
					fprintf(stderr,"# %d %s - Syntax error for Read - second arg incorrect\n",linNum,_tokenVal);
				}

				PC++;

				continue;
			}

			if(_tokenRef == WRITE)
			{
				PArray[PC].opcode = WRITE;
				//fprintf(stderr,"%s instruction identified\n",_tokenVal);

				// Go to Next Token 2nd
				linIndex++;
				_tokenRef = Lines[linNum].tokens[linIndex].ref;
				strcpy(_tokenVal,Lines[linNum].tokens[linIndex].val);

				if(_tokenRef == REG)
				{
					PArray[PC].reg_no = getRegNum(_tokenVal);
				}
				else
				{

					fprintf(stderr,"# %d %s - Syntax error for Write - second arg incorrect\n",linNum,_tokenVal);
				}

				PC++;

				continue;
			}

			if(_tokenRef == COMMENT)
			{

			}
	}

	//fprintf(stderr,"%d - 5 case identified\n",PArray[5].u.address);
	//fprintf(stderr,"%d - 15 case identified\n",PArray[15].u.address);
	//fprintf(stderr,"%d - 40 case identified\n",PArray[40].u.address);

	//fprintf(stderr,"%d - 21 case identified\n",PArray[21].u.address);
	//fprintf(stderr,"%d - 26 case identified\n",PArray[26].u.address);
	//fprintf(stderr,"%d - 30 case identified\n",PArray[30].u.address);
	//fprintf(stderr,"%d - 32 case identified\n",PArray[32].u.address);
	//fprintf(stderr,"%d - 35 case identified\n",PArray[35].u.address);
	//fprintf(stderr,"%d - 36 case identified\n",PArray[36].u.address);
	//fprintf(stderr,"%d - 40 case identified\n",PArray[40].u.address);

	if(err_flag !=ERROR){
		execute();
	}

	return 0;
}
