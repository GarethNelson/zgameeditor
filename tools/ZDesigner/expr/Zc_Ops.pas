unit Zc_Ops;

interface

uses Contnrs;

type
  TZcAssignType = (atAssign,atMulAssign,atDivAssign,atPlusAssign,atMinusAssign);
  TZcOpKind = (zcNop,zcMul,zcDiv,zcPlus,zcMinus,zcConst,zcIdentifier,zcAssign,zcIf,
          zcCompLT,zcCompGT,zcCompLE,zcCompGE,zcCompNE,zcCompEQ,
          zcBlock,zcNegate,zcOr,zcAnd,zcFuncCall,zcReturn,zcArrayAccess,
          zcFunction);

  TZcOp = class
  public
    Kind : TZcOpKind;
    Value : single;
    Id : string;
    Children : TObjectList;
    Ref : TObject;
    constructor Create(Owner : TObjectList); virtual;
    destructor Destroy; override;
    function ToString : string; virtual;
    function Child(I : integer) : TZcOp;
    procedure Optimize; virtual;
  end;

  TZcOpFunction = class(TZcOp)
  public
    Locals : TObjectList;
    Statements : TObjectList;
    constructor Create(Owner : TObjectList); override;
    destructor Destroy; override;
    function ToString : string; override;
    procedure Optimize; override;
  end;

  TZcOpVariableBase = class(TZcOp)
  public
    Ordinal : integer;
  end;

  TZcOpLocalVar = class(TZcOpVariableBase)
  public
    function ToString : string; override;
  end;

implementation

uses SysUtils;

constructor TZcOp.Create(Owner : TObjectList);
begin
  Owner.Add(Self);
  Children := TObjectList.Create(False);
end;

destructor TZcOp.Destroy;
begin
  FreeAndNil(Children);
end;

function TZcOp.Child(I : integer) : TZcOp;
begin
  Result := TZcOp(Children[I]);
end;

function TZcOp.ToString : string;
var
  I : integer;
begin
  case Kind of
    zcMul : Result := Child(0).ToString + '*' + Child(1).ToString;
    zcDiv : Result := Child(0).ToString + '/' + Child(1).ToString;
    zcPlus : Result := Child(0).ToString + '+' + Child(1).ToString;
    zcMinus : Result := Child(0).ToString + '-' + Child(1).ToString;
    zcConst : Result := FloatToStr(Value);
    zcIdentifier : Result := Id;
    zcAssign : Result := Child(0).ToString + '=' + Child(1).ToString;
    zcIf :
      begin
        Result := 'if(' + Child(0).ToString + ') ' + Child(1).ToString;
        if Assigned(Child(2)) then
          Result := Result + ' else ' + Child(2).ToString;
      end;
    zcCompLT : Result := Child(0).ToString + '<' + Child(1).ToString;
    zcCompGT : Result := Child(0).ToString + '>' + Child(1).ToString;
    zcCompLE : Result := Child(0).ToString + '<=' + Child(1).ToString;
    zcCompGE : Result := Child(0).ToString + '>=' + Child(1).ToString;
    zcCompNE : Result := Child(0).ToString + '!=' + Child(1).ToString;
    zcCompEQ : Result := Child(0).ToString + '==' + Child(1).ToString;
    zcBlock :
      begin
        Result := '{'#13#10;
        for I := 0 to Children.Count-1 do
          Result := Result + Child(I).ToString + '; ';
        Result := Result + '}'#13#10;
      end;
    zcNegate : Result := '-' + Child(0).ToString;
    zcOr : Result := Child(0).ToString + ' || ' + Child(1).ToString;
    zcAnd : Result := Child(0).ToString + ' && ' + Child(1).ToString;
    zcFuncCall :
      begin
        Result := Id + '(';
        for I := 0 to Children.Count-1 do
        begin
          if I>0 then
            Result := Result + ',';
          Result := Result + Child(I).ToString;
        end;
        Result := Result + ')';
      end;
    zcNop : Result := ';';       //Empty statement
    zcReturn : Result := 'return ' + Child(0).ToString + ';';
    zcArrayAccess:
      begin
        Result := Id + '[';
        for I := 0 to Children.Count-1 do
        begin
          if I>0 then
            Result := Result + ',';
          Result := Result + Child(I).ToString;
        end;
        Result := Result + ']';
      end;
  end;
end;

procedure TZcOp.Optimize;
var
  I : integer;

  procedure DoConstant(NewValue : single);
  begin
    if (Child(0).Kind=zcConst) and (Child(1).Kind=zcConst) then
    begin
      Kind := zcConst;
      Value := NewValue;
    end;
  end;

begin
  for I := 0 to Children.Count-1 do
    if Assigned(Child(I)) then Child(I).Optimize;
  case Kind of
    //todo: more optimizations
    zcMul : DoConstant(Child(0).Value * Child(1).Value);
    zcDiv : DoConstant(Child(0).Value / Child(1).Value);
    zcPlus : DoConstant(Child(0).Value + Child(1).Value);
    zcMinus : DoConstant(Child(0).Value - Child(1).Value);
    zcNegate :
      if Child(0).Kind=zcConst then
      begin
        Kind := zcConst;
        Value := Child(0).Value * -1;
      end;
  end;
end;

{ TZcOpFunction }

constructor TZcOpFunction.Create(Owner: TObjectList);
begin
  inherited;
  Kind := zcFunction;
  Statements := TObjectList.Create(False);
  Locals := TObjectList.Create(False);
end;

destructor TZcOpFunction.Destroy;
begin
  Statements.Free;
  Locals.Free;
  inherited;
end;

procedure TZcOpFunction.Optimize;
var
  I : integer;
begin
  for I := 0 to Statements.Count-1 do
    TZcOp(Statements[I]).Optimize;
end;

function TZcOpFunction.ToString: string;
var
  I : integer;
begin
  Result := '{'#13#10;           
  for I := 0 to Locals.Count-1 do
    Result := Result + TZcOp(Locals[I]).ToString;
  for I := 0 to Statements.Count-1 do
    Result := Result + TZcOp(Statements[I]).ToString;
  Result := Result + '}'#13#10;
end;

{ TZcOpVariableBase }


{ TZcOpLocalVar }

function TZcOpLocalVar.ToString: string;
begin
  Result := 'float ' + Id + ';'#13#10;
end;

end.
