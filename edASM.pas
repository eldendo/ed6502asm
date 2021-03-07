(**************************************
* edASM - an assembler for the 6502   *
* (c)2020-2021 by ir. Marc Dendooven  *
**************************************)

(* EBNF
--------------------------------------
program = {line} 'eof' .
line = [labeldef] [instruction] 'eol' .
labeldef = label [':'] .
instruction = mnemonic [argument] .
argument = immediate | direct | indirect | 'A' .
immediate = '#' value .
direct = value [',' ('X'|'Y') ] .
indirect = '(' value next .
next = ',' 'X' ')' | ')' [',' 'Y'] .
value = number | label .
*)

program edASM;
uses sysutils;

const debug=false;


type symbols = (mn_ADC,mn_AND,mn_ASL,mn_BCC,mn_BCS,mn_BEQ,mn_BIT,mn_BMI,mn_BNE,mn_BPL,mn_BRK,mn_BVC,mn_BVS,
        CLC,mn_CLD,mn_CLI,mn_CLV,mn_CMP,mn_CPX,mn_CPY,mn_DEC,mn_DEX,mn_DEY,mn_EOR,mn_INC,mn_INX,mn_INY,mn_JMP,
        mn_JSR,mn_LDA,mn_LDX,mn_LDY,mn_LSR,mn_NOP,mn_ORA,mn_PHA,mn_PHP,mn_PLA,mn_PLP,mn_ROL,mn_ROR,mn_RTI,mn_RTS,mn_SBC,mn_SEC,mn_SED,mn_SEI,mn_STA,mn_STX,mn_STY,
        mn_TAX,mn_TAY,mn_TSX,mn_TXA,mn_TXS,mn_TYA,s_eol,s_eof,s_label,s_num,s_tjoek,s_comma,s_lparen,s_rparen,s_colon,r_X,r_Y,r_A);

const mn_names: array[mn_ADC..mn_TYA] of string = ('ADC','AND','ASL','BCC','BCS','BEQ','BIT','BMI','BNE','BPL','BRK','BVC','BVS',
    'CLC','CLD','CLI','CLV','CMP','CPX','CPY','DEC','DEX','DEY','EOR','INC','INX','INY','JMP',
    'JSR','LDA','LDX','LDY','LSR','NOP','ORA','PHA','PHP','PLA','PLP','ROL','ROR','RTI','RTS','SBC','SEC','SED','SEI','STA','STX','STY',
    'TAX','TAY','TSX','TXA','TXS','TYA');

var ch: char = #12;
    sym: symbols;
    text: string;
    val: integer;

procedure err(s: string);
begin
    writeln(' *** ERROR: ',s);
    halt
end;

procedure dbug(msg: string);
begin
    if debug then writeln(' >>>',msg)
end;

procedure getCh;
begin
    write(ch);
    if eof then ch := #0 else read(ch);
    ch := upcase(ch);  
end;

procedure skipWhite;
begin
    while ch in [#1..#9,#11..#32] do getCh
end;

procedure alfanum;
var i: symbols;
begin
    sym := s_label;
    text := '';
    while ch in ['A'..'Z','0'..'9'] do 
        begin
            text := text+ch;
            getCh
        end;
    for i := mn_ADC to mn_TYA do
            if text = mn_names[i] then sym := i;
    if text='X' then sym := r_X;
    if text='Y' then sym := r_Y;
    if text='A' then sym := r_A
end;

procedure decimal;
begin
    sym := s_num;
    val := 0;
    while ch in ['0'..'9'] do 
        begin
            val := 10*val+ord(ch)-ord('0');
            getCh
        end
end;

procedure hexadecimal;
begin
    sym := s_num;
    val := 0;
    getCh;
    while ch in ['0'..'9','A'..'F'] do 
        begin
            if ch in ['0'..'9'] then val := 16*val+ord(ch)-ord('0')
                                else val := 16*val+ord(ch)-ord('A')+10;
            getCh
        end
end;

procedure getSym;
begin
    skipWhite;
    if ch=';' then while ch <> #10 do getCh; //skip comments
    skipWhite;
    case ch of
    #0 : begin sym := s_eof; getCh end;
    #10: begin sym := s_eol; getCh end;
    'A'..'Z': alfanum;
    '0'..'9': decimal;
    '#': begin sym := s_tjoek; getCh end;
    ',': begin sym := s_comma; getCh end;
    '$': hexadecimal;
    '(': begin sym := s_lparen; getCh end;
    ')': begin sym := s_rparen; getCh end;
    ':': begin sym := s_colon; getCh end;
    else
        err('unexpected character '''+ch+'''')
    end
end;
//////////////////////////////////////////////////////////////////////
procedure expect (s: symbols);
begin
    if sym <> s then begin writeln(' *** ERROR: ',s,' expected but ',sym,' found');halt end
end;

procedure consume (s: symbols);
begin
    expect(s);
    getSym
end;

procedure line;

    procedure labeldef;
    begin
        dbug('labeldef found');
        getSym;
        if sym = s_colon then getSym //skip optional colon
    end;
    
    procedure instruction;
    
        procedure direct_or_relative;
            
            procedure indexed;
            begin
                dbug('indexed');
                getSym;
                case sym of
                    r_X: dbug('by X');
                    r_Y: dbug('by Y')
                else err('X or Y expected ')
                end;
                getSym
            end;
            
        begin //direct_or_relative
            dbug('direct or relative '+intToStr(val));
            getSym;
            case sym of
                s_comma: indexed;
                s_eol: dbug('not indexed');
            else err('unexpected symbol')
            end
        end;
        
        procedure indirect;
        begin
            dbug('indirect');
            getSym;
            consume(s_num);
            dbug('indirect '+intToStr(val));
            if sym=s_comma then begin getSym; consume(r_X);consume(s_rparen);dbug('indexed indirect (X) ') end
            else begin
                    consume(s_rparen);
                    if sym=s_comma then begin getSym;consume(r_Y);dbug('indirect indexed (Y)') end
                                   else dbug('absolute indexed')
                 end
        end;
    
    begin // instruction
        dbug('instruction found');
        getSym;
        case sym of
            s_eol: dbug('implied');
            s_tjoek: begin getSym; consume(s_num); dbug('immediate '+intToStr(val)) end;
            s_num: direct_or_relative;
            s_lparen: indirect;
            r_A: begin getSym;dbug('Accumulator') end
        else err('wrong argument')
        end
    end;

begin //line
//    writeln(sym);
    if sym = s_label then labeldef;
    if sym in [mn_ADC..mn_TYA] then instruction;
    if (sym <> s_eof) and (sym <> s_eol) then err('unexpected symbol');    
    if sym = s_eol then getSym;
end;

begin //main
    writeln('+-----------------------------------+');
    writeln('| edASM - an assembler for the 6502 |');
    writeln('|  (c)2020-2021 ir. Marc Dendooven  |');
    writeln('+-----------------------------------+');
    writeln('testing lexer and parser');
    getCh;
    getSym;
    while sym <> s_eof do line 
end.
