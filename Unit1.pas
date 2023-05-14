unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, U_Math, UniTypes;

type
  TForm1 = class(TForm)
    EditLightSource1: TEdit;
    EditAngleInBetween: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    EditLightSource2: TEdit;
    Label3: TLabel;
    procedure EditAngleInBetweenChange(Sender: TObject);
    procedure EditLightSource1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure Renew;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function FormatFloat(AFloat : extended) : string;
var
  xPointPos : integer;
  i : integer;
begin
  Result := FloatToStrF(AFloat, ffFixed, 8, 2);

  xPointPos := Pos(',', Result);
  if xPointPos = -1 then
    xPointPos := Pos('.', Result);

  if xPointPos <> 0 then
    begin
      for i := Length(Result) downto xPointPos do
        begin
          if (Result[i] = '0') or (Result[i] = '.') or (Result[i] = ',') then
            SetLength(Result, Length(Result) - 1)
          else
            Break;
        end;
    end;
end;

procedure TForm1.Renew;
var
  xAngleInBetween : real;
  xSourceAngle1 : real;
  xSourceAngle2 : real;
begin
  xSourceAngle1 := StrToFloatDef(EditLightSource1.Text, NaN);
  xAngleInBetween := StrToFloatDef(EditAngleInBetween.Text, NaN);

  if IsNan(xSourceAngle1) or IsNan(xAngleInBetween) then
    EditLightSource2.Text := 'Ошибка :)'
  else
    begin


      xSourceAngle2 :=  RadToDeg(GetPiAngle( DegToRad(xSourceAngle1) + DegToRad(xAngleInBetween)));

    //  xSourceAngle2 := RadToDeg(GetMinAngle(DegToRad(xSourceAngle1), DegToRad(xAngleInBetween)));


      //xSourceAngle2 := Frac((xSourceAngle1 + xAngleInBetween) / 360) * 360;



      //if xSourceAngle2 < 0 then
        //xSourceAngle2 := 360 + xSourceAngle2;

      EditLightSource2.Text := FormatFloat(xSourceAngle2);
    end;
end;

procedure TForm1.EditAngleInBetweenChange(Sender: TObject);
begin
  Renew;

end;

procedure TForm1.EditLightSource1Change(Sender: TObject);
begin
  Renew;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Renew;
end;

end.
