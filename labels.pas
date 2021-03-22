(*****************************************************************
* Label unit                                                     *
* This file is part of ed6502ASM                                 *
* Copyright (c)2021 by ir. Marc Dendooven                        *
*                                                                *
*****************************************************************)


unit labels;

interface

type labelValues = -1..$FFFF;

procedure newLabel(name: string; value: word);
function getLabel(name: string): labelValues;
procedure alterLastLabel(value: word);

implementation

type labelNodePtr = ^labelNode;
     labelNode = record
                    name:string;
                    value: word;
                    next: labelNodePtr
                 end;
                 
var labList: labelNodePtr = Nil;
    
procedure newLabel(name: string; value: word);
var tmp: labelNodePtr;
begin
    if getLabel(name)<>-1 then begin writeln('ERROR: Label "',name,'" has already been used'); halt end;
    tmp := new(labelNodePtr);
    tmp^.name := name;
    tmp^.value := value;
    tmp^.next := labList;
    labList := tmp
end;

function getLabel(name: string): labelValues; 
var tmp: labelNodePtr; 
begin
    tmp := labList;
    while tmp<>nil do
        begin
            if tmp^.name = name then exit(tmp^.value)
                                else tmp := tmp^.next
        end;
    getLabel := -1
end; 

procedure alterLastLabel(value: word);
begin
    if labList = nil then begin writeln('ERROR: label list is empty'); halt end; 
    labList^.value := value
end;    

end.
