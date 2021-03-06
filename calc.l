%{
/*
This file is part of Reverse Notation Calc.

    Reverse Notation Calc is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

*/

#include "mystack.h"
#include <stdlib.h>
#include <math.h>

int copy_stack_to_stack(ch_stack* in_stack, ch_stack* out_stack);
int push_stack_to_stack(ch_stack* in_stack, ch_stack* out_stack);
int pull_last_word_from_stack(ch_stack* stack, ch_stack* out_stack);

int int_value;
char* char_value;

typedef enum {
    LexNumber=1001,
    LexPlus,
    LexMinus,
    LexDiv,
    LexMult,
    LexEnd,
    LexApostroph,
    LexDoubleApostroph,
    LexWordConcat,
    LexWordMult,
    LexNumberConcat,
    LexWord,
    LexUnknown,
} LexType;

my_stack calc_stack;
ch_stack char_stack;
ch_stack temp_stack;

int word_opened;
int apostroph_count;
int end_file;

%}

%s SKIPERROR

digit             [0-9]
number            {digit}+
word              [a-zA-Z ]+
apostroph         \"
double_apostroph  \"\"

%%

{word}  {
          char_value = yytext;
          return LexWord;
        }
{apostroph} {
          return LexApostroph;
        }
{double_apostroph} {
          return LexDoubleApostroph;
        }
\+s     {
          return LexWordConcat; }
\*s     {
          return LexWordMult; }
\+n     {
          return LexNumberConcat; }
{number}    {
		  int_value=atoi(yytext);
		  return LexNumber; }
\+		{
		  return LexPlus; }
\-		{
		  return LexMinus; }
\/		{
		  return LexDiv; }
\*		{
		  return LexMult; }
^[ \t]*\n	{
		}
\n		{
		  return LexEnd; }
[ \t]		{ }

<SKIPERROR>[^\n]* {}
%%

int process_command(int token)
{
    switch (token) {
    
    case LexApostroph: {
        if (word_opened == 1) { 
            if (apostroph_count % 2 != 0) {
                return -1;
            }
            
            word_opened = 0;
            apostroph_count = 0;
        } else if (word_opened == 0) {
            word_opened = 1;
        }
        
        break; }
    case LexDoubleApostroph: {
        apostroph_count++;
        char_stack_push(&char_stack, '\"');
        break; }
    case LexWord: {
        if (strcmp(char_value, " ") != 0) {
            if (word_opened == 0) {
                return -1;
            }
            int i = 0;
            while (i < strlen(char_value)) {
                char_stack_push(&char_stack, char_value[i++]);
            }
            char_stack_push(&char_stack, "\0");
        }
        break; }
    case LexNumberConcat: {
        if (word_opened == 1) {
            return -1;
        }
        if (my_stack_count == 0) {
            return -1;
        }
        
        char emptiness = char_stack_pull(&char_stack);
        int number = my_stack_pull(&calc_stack);
        
        int number_length = floor(log10(abs(number))) + 1;
        char char_number[] = "\0";
        sprintf(char_number, "%d", number);
        
        for (int i = 0; i < number_length; i++) {
            char_stack_push(&char_stack, (char)char_number[i]);
        }
        char_stack_push(&char_stack, "\0");
        
        break; }
    case LexWordConcat: {
        if (word_opened == 1) {
            return -1;
        }
        
        if (!pull_last_word_from_stack(&char_stack, &temp_stack)) {
            return -1;
        }
        if (!push_stack_to_stack(&temp_stack, &char_stack)) {
            return -1;
        }
        
        char_stack_clean(&temp_stack);
        
        break; }
        
    case LexWordMult: {
        if (word_opened == 1) {
            return -1;
        }
        
        int count = my_stack_pull(&calc_stack);
        if (count > 0) {
            if (!pull_last_word_from_stack(&char_stack, &temp_stack)) {
                return -1;
            }
            for (int i = 0; i < count; i++) {
                if (!copy_stack_to_stack(&temp_stack, &char_stack)) {
                    return -1;
                }
            }
            
            char_stack_clean(&temp_stack);
        }
        
        
        break; }
    case LexNumber:
        if (word_opened == 1) {
            return -1;
        }
        my_stack_push(&calc_stack, int_value);
        if (my_stack_is_full(&calc_stack)) {
            return -1;
        }
        break;
    case LexPlus: {
        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int a=my_stack_pull(&calc_stack);

        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int b=my_stack_pull(&calc_stack);

        my_stack_push(&calc_stack, a+b);
        if (my_stack_is_full(&calc_stack)) {
            return -1;
        }
        break;}
    case LexMinus: {
        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int a=my_stack_pull(&calc_stack);

        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int b=my_stack_pull(&calc_stack);

        my_stack_push(&calc_stack, b-a);
        if (my_stack_is_full(&calc_stack)) {
            return -1;
        }
        break;}
    case LexDiv: {
        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int a=my_stack_pull(&calc_stack);

        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int b=my_stack_pull(&calc_stack);

        my_stack_push(&calc_stack, b/a);
        if (my_stack_is_full(&calc_stack)) {
            return -1;
        }
        break;}
    case LexMult: {
        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int a=my_stack_pull(&calc_stack);

        if (my_stack_is_empty(&calc_stack)) {
            return -1;
        }
        int b=my_stack_pull(&calc_stack);

        my_stack_push(&calc_stack, b*a);
        if (my_stack_is_full(&calc_stack)) {
            return -1;
        }
        break;}
    case LexEnd:
    case 0:
        return 0;
    case LexUnknown:
        return -1;

    }
    return 1;
}

int copy_stack_to_stack(ch_stack* in_stack, ch_stack* out_stack)
{
    if (char_stack_count(in_stack) == 0)
    {
        return 0;
    }
    int index = char_stack_count(in_stack);
    while (index != 0)
    {
        char value = char_stack_get_deep(in_stack, --index);
        char_stack_push(out_stack, value);
    }
}

int push_stack_to_stack(ch_stack* in_stack, ch_stack* out_stack)
{
    if (char_stack_count(in_stack) == 0)
    {
        return 0;
    }
    while (char_stack_count(in_stack) != 0)
    {
        char value = char_stack_pull(in_stack);
        char_stack_push(out_stack, value);
    }
    
    return 1;
}

int pull_last_word_from_stack(ch_stack* stack, ch_stack* out_stack) 
{
    if (char_stack_count(stack) == 0)
    {
        return 0;
    }
    char_stack_push(out_stack, "\0");
    
    int terminator_count = 0;
        
    while (terminator_count != 2) {
        if (char_stack_count(stack) == 0) {
            break;
        }
        
        char temp_stack_char = char_stack_pull(stack);
            
        if (temp_stack_char == NULL
            || temp_stack_char == "\0" 
            || temp_stack_char == -40 
            || temp_stack_char == -44 
            || temp_stack_char == 24
            || temp_stack_char == -8
        ) {
            terminator_count++;
        } else {
            char_stack_push(out_stack, temp_stack_char);
        }
    }
    
    return 1;
}

int calc_line()
{
    int token = yylex();
    if (token == 0) {
        return 1;
    }

    while (1) {
        int cmd_res = process_command(token);
        if (cmd_res == 0) {
            break;
        }
        else if (cmd_res == -1) {
            fprintf(stderr, "Syntax error\n");
            reset_flags_and_stacks();
            return 0;
        }
        token = yylex();
    }
    
    if (my_stack_is_empty(&calc_stack) && char_stack_is_empty(&char_stack)) {
        fprintf(stderr, "Character stack is empty but required value");
        return 0;
    }

    if (!my_stack_is_empty(&calc_stack)) {
        fprintf(stderr, "Calculation stack: %d\n", my_stack_pull(&calc_stack));
    }
    
    fprintf(stderr, "Character stack: \n");
    
    int stack_count = char_stack_count(&char_stack);
    
    for (int i = 0; i < stack_count; ++i) {
        char value = char_stack_get_deep(&char_stack, i);
        fprintf(stderr, "%c", value);
    }
    fprintf(stderr, "\n");
    
    reset_flags_and_stacks();   
    
    if (!my_stack_is_empty(&calc_stack)) {
        fprintf(stderr, "Stack not empty after calculation\n");
        return 0;
    }

    return 1;
}

void reset_flags_and_stacks()
{
    end_file = 0;
    word_opened = 0;
    apostroph_count = 0;
    
    my_stack_clean(&calc_stack);
    char_stack_clean(&char_stack);
    char_stack_clean(&temp_stack);
}

void calc()
{
    while (!end_file) {
        fprintf(stderr, "parse line\n");
        if (calc_line() == 0) {
            printf("FAIL\n");
            BEGIN(SKIPERROR);
            yylex();
            BEGIN(INITIAL);
        }
        else {
            printf("OK\n");
        }
        fprintf(stderr, "line parsed\n");
    }
}

int main(void)
{
    my_stack_init(&calc_stack, 100);
    char_stack_init(&char_stack, 100);
    char_stack_init(&temp_stack, 100);
    end_file = 0;
    word_opened = 0;
    apostroph_count = 0;

    calc();

    my_stack_done(&calc_stack);
    char_stack_done(&char_stack);
    char_stack_done(&temp_stack);
    return 0;
}

int yywrap(void)
{
    end_file = 1;
    return 1;
}
