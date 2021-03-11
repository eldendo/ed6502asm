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

type symbols = (s_mnemonic,s_eol,s_eof,s_label,s_num,s_tjoek,s_comma,s_lparen,s_rparen,s_colon,s_X,s_Y,s_A);

     mnemonics = (mn_ADC,mn_AND,mn_ASL,mn_BCC,mn_BCS,mn_BEQ,mn_BIT,mn_BMI,mn_BNE,mn_BPL,mn_BRK,mn_BVC,mn_BVS,
        CLC,mn_CLD,mn_CLI,mn_CLV,mn_CMP,mn_CPX,mn_CPY,mn_DEC,mn_DEX,mn_DEY,mn_EOR,mn_INC,mn_INX,mn_INY,mn_JMP,
        mn_JSR,mn_LDA,mn_LDX,mn_LDY,mn_LSR,mn_NOP,mn_ORA,mn_PHA,mn_PHP,mn_PLA,mn_PLP,mn_ROL,mn_ROR,mn_RTI,
        mn_RTS,mn_SBC,mn_SEC,mn_SED,mn_SEI,mn_STA,mn_STX,mn_STY,mn_TAX,mn_TAY,mn_TSX,mn_TXA,mn_TXS,mn_TYA);
     
     memoryModes = (mm_Imm,mm_Acc,mm_ZP,mm_ZPX,mm_ZPY,mm_Abs,mm_AbX,mm_AbY,mm_Ind,mm_inX,mm_inY,mm_Imp,mm_Rel);

const NrArg: array[memoryModes] of 0..2 = (1,0,1,1,1,2,2,2,2,1,1,0,1);

const mn_names: array[mnemonics] of string = 
    ('ADC','AND','ASL','BCC','BCS','BEQ','BIT','BMI','BNE','BPL','BRK','BVC','BVS',
    'CLC','CLD','CLI','CLV','CMP','CPX','CPY','DEC','DEX','DEY','EOR','INC','INX','INY','JMP',
    'JSR','LDA','LDX','LDY','LSR','NOP','ORA','PHA','PHP','PLA','PLP','ROL','ROR','RTI',
    'RTS','SBC','SEC','SED','SEI','STA','STX','STY','TAX','TAY','TSX','TXA','TXS','TYA');
    
const opcode: array[mnemonics,memoryModes] of integer = (

{      Imm,Acc,ZP ,ZPX,ZPY,Abs,AbX,AbY,Ind,inX,inY,Imp,Rel}
{ADC} ($69, -1,$65,$75, -1,$6D,$7D,$79, -1,$61,$71, -1, -1),
{AND} ($29, -1,$25,$35, -1,$2D,$3D,$39, -1,$21,$31, -1, -1),
{ASL} ( -1,$0A,$06,$16, -1,$0E,$1E, -1, -1, -1, -1, -1, -1),
{BCC} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$90),
{BCS} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$B0),
{BEQ} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$F0),
{BIT} ( -1, -1,$24, -1, -1,$2C, -1, -1, -1, -1, -1, -1, -1),
{BMI} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$30),
{BNE} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$D0),
{BPL} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$10),
{BRK} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$00, -1),
{BVC} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$50),
{BVS} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$70),
{CLC} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$18, -1),
{CLD} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$D8, -1),
{CLI} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$58, -1),
{CLV} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$B8, -1),
{CMP} ($C9, -1,$C5,$D5, -1,$CD,$DD,$D9, -1,$C1,$D1, -1, -1),
{CPX} ($E0, -1,$E4, -1, -1,$EC, -1, -1, -1, -1, -1, -1, -1),
{CPY} ($C0, -1,$C4, -1, -1,$CC, -1, -1, -1, -1, -1, -1, -1),
{DEC} ( -1, -1,$C6,$D6, -1,$CE,$DE, -1, -1, -1, -1, -1, -1),
{DEX} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$CA, -1),
{DEY} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$88, -1),
{EOR} ($49, -1,$45,$55, -1,$4D,$5D,$59, -1,$41,$51, -1, -1),
{INC} ( -1, -1,$E6,$F6, -1,$EE,$FE, -1, -1, -1, -1, -1, -1),
{INX} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$E8, -1),
{INY} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$C8, -1),
{JMP} ( -1, -1, -1, -1, -1,$4C, -1, -1,$6C, -1, -1, -1, -1),
{JSR} ( -1, -1, -1, -1, -1,$20, -1, -1, -1, -1, -1, -1, -1),
{LDA} ($A9, -1,$A5,$B5, -1,$AD,$BD,$B9, -1,$A1,$B1, -1, -1),
{LDX} ($A2, -1,$A6,$B6, -1,$AE, -1,$BE, -1, -1, -1, -1, -1),
{LDY} ($A0, -1,$A4,$B4, -1,$AC,$BC, -1, -1, -1, -1, -1, -1),
{LSR} ( -1,$4A,$46,$56, -1,$4E,$5E, -1, -1, -1, -1, -1, -1),
{NOP} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$EA, -1),
{ORA} ($09, -1,$05,$15, -1,$0D,$1D,$19, -1,$01,$11, -1, -1),
{PHA} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$48, -1),
{PHP} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$08, -1),
{PLA} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$68, -1),
{PLP} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$28, -1),
{ROL} ( -1,$2A,$26,$36, -1,$2E,$3E, -1, -1, -1, -1, -1, -1),
{ROR} ( -1,$6A,$66,$76, -1,$6E,$7E, -1, -1, -1, -1, -1, -1),
{RTI} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$40, -1),
{RTS} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$60, -1),
{SBC} ($E9, -1,$E5,$F5, -1,$ED,$FD,$F9, -1,$E1,$F1, -1, -1),
{SEC} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$38, -1),
{SED} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$F8, -1),
{SEI} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$78, -1),
{STA} ( -1, -1,$85,$95, -1,$8D,$9D,$99, -1,$81,$91, -1, -1),
{STX} ( -1, -1,$86, -1,$96,$8E, -1, -1, -1, -1, -1, -1, -1),
{STY} ( -1, -1,$84,$94, -1,$8C, -1, -1, -1, -1, -1, -1, -1),
{TAX} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$AA, -1),
{TAY} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$A8, -1),
{TSX} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$BA, -1),
{TXA} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$8A, -1),
{TXS} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$9A, -1),
{TYA} ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,$98, -1)
);

var ch: char = #10; // echoed before reading. LF character as start value is safe
    sym: symbols;
    mnem: mnemonics;
    mMode: memoryModes;
    text: string;
    val: integer;
    address: 0..$FFFF;

procedure err(s: string);
begin
    writeln(' *** ERROR: ',s);
    halt
end;

procedure dbug(msg: string);
begin
    if debug then writeln(' >>>',msg)
end;

procedure emit(address:word;opc:byte;argument:word);
begin
    write(hexStr(address,4),': ',hexStr(opc,2),' ');
    case nrArg[mMode] of
        0: writeln;
        1: writeln(hexStr(val,2));
        2: writeln(hexStr(lo(val),2),hexStr(hi(val),2))
    end
end;

procedure getCh;
begin
    write(ch); //echo previous character
    if eof then ch := #0 else read(ch);
    ch := upcase(ch);  
end;
////////////////////////////// scanner ////////////////////////////
procedure skipWhite;
begin
    while ch in [#1..#9,#11..#32] do getCh
end;

procedure alfanum;
var i: mnemonics;
begin
    sym := s_label;
    text := '';
    while ch in ['A'..'Z','0'..'9'] do 
        begin
            text := text+ch;
            getCh
        end;
    for i in mnemonics do
            if text = mn_names[i] then begin sym := s_mnemonic; mnem := i end;
    if text='X' then sym := s_X;
    if text='Y' then sym := s_Y;
    if text='A' then sym := s_A
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
///////////////////////////// parser //////////////////////////////////
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
        
        var opc: integer;
    
        procedure useLabel;
        begin
            writeln;
            writeln(' *** WARNING: using label but not yet implemented');
            writeln(' *** using stub value 7 instead');
            val:=7
        end;
    
        procedure direct_or_relative;
            
            procedure indexed;
            begin
                dbug('indexed');
                getSym;
                case sym of
                    s_X: begin dbug('by X'); if val<=255 then mMode := mm_zpX else mMode := mm_abX end;
                    s_Y: begin dbug('by Y'); if val<=255 then mMode := mm_zpY else mMode := mm_abY end
                else err('X or Y expected ')
                end;
                getSym
            end;
            
            procedure notIndexed;
            begin
                
            end;
            
        begin //direct_or_relative
        
            if sym=s_label then useLabel; 
            dbug('direct or relative '+intToStr(val));
            getSym;
            case sym of
                s_comma: indexed;
                s_eol: begin 
                            dbug('not indexed');
                            if mnem in [mn_BCC,mn_BCS,mn_BEQ,mn_BMI,mn_BNE,mn_BPL,mn_BVC,mn_BVS] 
                                then if val>255 then err('one byte of data expected') else mMode := mm_rel
                                else if val>255 then mMode := mm_abs else mMode := mm_zp
                       end
            else err('unexpected symbol')
            end
        end;
        
        procedure indirect;
        begin
            dbug('indirect');
            getSym;
            if sym=s_label then useLabel else expect(s_num);
            dbug('indirect '+intToStr(val));
            getSym;
            if sym=s_comma 
                then begin
                        getSym;
                        consume(s_X);
                        consume(s_rparen);
                        dbug('indexed indirect (X) '); // always ZP
                        mMode := mm_inX
                     end
                else begin
                        consume(s_rparen);
                        if sym=s_comma 
                            then 
                                begin
                                    getSym;
                                    consume(s_Y);
                                    dbug('indirect indexed (Y)'); //always ZP
                                    mMode := mm_inY
                                end
                            else begin dbug('indirect'); mMode := mm_Ind end //always JMP (word)
                     end
        end;
        
        procedure immediate;
        begin
            mMode := mm_imm;
            getSym;
            if sym=s_label then useLabel else expect(s_num);
            dbug('immediate '+intToStr(val));
            getSym
        end;
    
    begin // instruction
        dbug('instruction found');
        getSym;
        case sym of
            s_eol: begin mMode := mm_imp; dbug('implied') end;
            s_tjoek: immediate;
            s_num,s_label: direct_or_relative;
            s_lparen: indirect;
            s_A: begin mMode := mm_acc; getSym;dbug('Accumulator') end
            else err('wrong argument')
        end;
//        writeln;writeln(mnem,' ',mMode);
        opc := opcode[mnem,mMode];
        if opc = -1 then err('Not a valid memory mode for this mnemonic');
        emit(address,opc,val)
    end;

begin //line
//    writeln(sym);
    if sym = s_label then labeldef;
    if sym = s_mnemonic then instruction;
    if (sym <> s_eof) and (sym <> s_eol) then err('unexpected symbol');    
    if sym = s_eol then getSym;
end;

begin //main
    writeln('+-----------------------------------+');
    writeln('| edASM - an assembler for the 6502 |');
    writeln('|  (c)2020-2021 ir. Marc Dendooven  |');
    writeln('+-----------------------------------+');
    writeln('testing scanner, parser and translator');
    writeln('labels are recognized but not used');
    writeln('addresscount not implemented yet');
    getCh;
    getSym;
    while sym <> s_eof do line
end.
