(*****************************************************************
* PrintOut unit                                                  *
* This file is part of ed6502ASM                                 *
* Copyright (c)2021 by ir. Marc Dendooven                        *
*                                                                *
*****************************************************************)

unit printOut;

interface

type printModes = (m_list,m_basic);

    procedure openPrintMode(pm: printModes);
    procedure closePrintMode;

    procedure emit(address:word; bytes:byte; opc:byte; arg:word; var org:boolean);

implementation

    var printMode: printModes;
        LnNum: cardinal;
        

    procedure openPrintMode(pm: printModes);

        procedure basic;
        begin
            LnNum := 1000;
            writeln('cut and past following lines in (vice) emulator');writeln;
            writeln('10 print chr$(147);');    
            writeln('20 print "     +----------------------------+"');
            writeln('30 print "     !     eldendo''s c64 loader   !"');  
            writeln('40 print "     ! (c)2021 ir. marc dendooven !"');
            writeln('50 print "     +----------------------------+":print');
            writeln('120 let a = 49152');
            writeln('130 read b');
            writeln('140 if b=-1 then 250');    
            writeln('150 if b=-2 then 200');
            writeln('160 poke a,b');
            writeln('170 let a=a+1');
            writeln('180 goto 130');
            writeln('200 read a');
            writeln('210 print "org found. new address is: ",a');  
            writeln('220 goto 130');
            writeln('250 print: input"run from $c000 (49152) [y/n]";i$');
            writeln('260 if i$<>"n" then sys 49152:end');
            writeln('270 print:print"start program with sys <address>');
        end;


    begin
        printMode := pm;
        case printmode of
            m_list: ;
            m_basic: basic;
        end

    end;

    procedure closePrintMode;
    begin
        case printmode of
            m_list: ;
            m_basic: begin writeln(lnNum,' data -1'); writeln('run'); writeln end;
        end
    end;

    procedure emit(address:word; bytes:byte; opc:byte; arg:word; var org:boolean);

        procedure list;
        begin
            write(hexStr(address,4),': ',hexStr(opc,2));
            case bytes of
                1: writeln;
                2: writeln(' ',hexStr(arg,2));
                3: writeln(' ',hexstr(lo(arg),2),hexStr(hi(arg),2))
            end
        end;
        
        procedure basic;
        begin
            if org then begin writeln(lnNum,' data ',-2,',',address);inc(lnNum); org := false end;
            write(lnNum,' data ',opc);inc(lnNum);
            case bytes of
                1: writeln;
                2: writeln(',',lo(arg));
                3: writeln(',',lo(arg),',',hi(arg))
            end
        end;


    begin
        case printMode of
            m_list: list;
            m_basic: basic;
        end
    end;
        
end.
