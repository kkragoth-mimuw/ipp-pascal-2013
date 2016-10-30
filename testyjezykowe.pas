unit testyjezykowe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Menus;

type
  {hack na modyfikowanie dlugosci w funkcji}
  SArray = array of string;

  { Opisuje stan jaki ma wyswietlac kontrolka }
  Stany = (nieWczytanoPliku, sprawdz, nastepny);

  { TOkno }
  TOkno = class(TForm)
    Testuj: TButton;
    Zakoncz: TButton;
    Wyrazy: TGroupBox;
    Zdanie: TGroupBox;
    Kontrolki: TPanel;
    StaticBledne: TLabel;
    IloscPoprawnych: TLabel;
    IloscBlednych: TLabel;
    IloscTestow: TLabel;
    StaticTest: TLabel;
    StaticPoprawne: TLabel;
    OpenDialog1: TOpenDialog;
    procedure LabelDragDrop(Sender, Source: TObject; X, Y: integer);
    procedure LabelDragOver(Sender, Source: TObject; X, Y: integer;
      State: TDragState; var Accept: boolean);
    procedure TestujClick(Sender: TObject);
    procedure ZakonczClick(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
  end;

const
  {odstepy}
  ODSTEP_H = 7;
  ODSTEP_V = 35;
  ROZMIAR_CZCIONKI = 19;

  KROPKA = '.';
  PRZECINEK = ',';
  WYKRZYKNIK = '!';
  DO_WSTAWIENIA = '>';
  WOLNE_POLE = '...';

  KONIEC_ZDANIA = '---';
  KONIEC_TESTU = '@';

var
  Okno: TOkno;

  {Plik trzymający teksty}
  f: TextFile;

  Stan: stany;

  nrObecnegoTestu, liczbaTestow: integer;

  {Tablice przechowujace wyrazy}
  WyrazyZdania: array of ansistring;
  WyrazyDoWstawienia: array of ansistring;
  Odpowiedzi: array of ansistring;

  IleBlednych, IlePoprawnych, IloscWolnychMiejsc: integer;

implementation

procedure ZaladujTest() forward;
procedure CzyscWszystko() forward;
procedure SprawdzPoprawnosc() forward;
procedure DodajDoTablicy(s: string; var A: SArray) forward;
procedure UaktualnijInformacje() forward;

{$R *.lfm}

{ TOkno }

procedure TOkno.ZakonczClick(Sender: TObject);
begin
  if MessageDlg('Wyjść?', mtConfirmation, [mbOK, mbCancel], 0) = mrOk then
  begin
    if Stan <> nieWczytanoPliku then
      CloseFile(f);
    Application.Terminate;
  end;
end;

procedure UaktualnijInformacje();
begin
  Okno.IloscTestow.Caption := (IntToStr(nrObecnegoTestu) + '/' +
    IntToStr(liczbaTestow));
  Okno.IloscBlednych.Caption := IntToStr(IleBlednych);
  Okno.IloscPoprawnych.Caption := IntToStr(IlePoprawnych);
end;

procedure TOkno.TestujClick(Sender: TObject);
begin
  case Stan of

    nieWczytanoPliku:
    begin
      if OpenDialog1.Execute then
      begin
        AssignFile(f, openDialog1.FileName);
        Reset(f);
        IlePoprawnych := 0;
        IleBlednych := 0;
        Readln(f, liczbaTestow);
        nrObecnegoTestu := 1;
        UaktualnijInformacje();
        CzyscWszystko();
        ZaladujTest();
        Stan := sprawdz;
        Testuj.Caption := 'Sprawdź';
      end;
    end;

    sprawdz:
    begin
      if IloscWolnychMiejsc > 0 then
        if (MessageDlg('Nie wypełniłeś wszystkiego. Kontynuować?',
          mtConfirmation, [mbOK, mbCancel], 0) = mrOk) then
          IloscWolnychMiejsc := 0;

      if IloscWolnychMiejsc = 0 then
      begin
        SprawdzPoprawnosc();
        if nrObecnegoTestu = liczbaTestow then
        begin
          CloseFile(f);
          Stan := nieWczytanoPliku;
          Testuj.Caption := 'Koniec testów!';
        end
        else
        begin
          Testuj.Caption := 'Następny test';
          stan := nastepny;
        end;
        UaktualnijInformacje();
      end;
    end;

    nastepny:
    begin
      CzyscWszystko();
      ZaladujTest();
      Testuj.Caption := 'Sprawdź';
      Stan := sprawdz;
      Inc(nrObecnegoTestu);
      UaktualnijInformacje();
    end;
  end;
end;


procedure CzyscWszystko();

  procedure Czysc(Pole: TGroupBox);
  var
    i: integer;
    tmp: TComponent;
  begin
    for i := 0 to Pole.ComponentCount - 1 do
    begin
      tmp := Pole.Components[0];
      (tmp as TLabel).Visible := False;
      Pole.RemoveComponent(tmp);
    end;
  end;

begin
  SetLength(Odpowiedzi, 0);
  Czysc(Okno.Wyrazy);
  Czysc(Okno.Zdanie);
end;

procedure formatujTekst(Area: TGroupBox);
var
  i, k, odstep: integer;
  poprzedni: TLabel;
begin
  k := 0;
  for i := 1 to Area.ComponentCount - 1 do
  begin
    with Area.Components[i] as TLabel do
    begin
      if (Caption = KROPKA) or (Caption = PRZECINEK) then
        odstep := 2
      else
        odstep := ODSTEP_H;
      poprzedni := Area.Components[i - 1] as TLabel;
      Left := poprzedni.Left + poprzedni.Width + odstep;
      if Left + Width > Area.Width then // przechodzimy do nowej linii
      begin
        Inc(k);
        Left := 0;
      end;
      Top := (k + 1) * ODSTEP_V;
    end;
  end;
end;

procedure dodajSlowo(s: string; Ojciec: TGroupBox);
var
  Obj: TLabel;
begin
  Obj := TLabel.Create(Okno);
  with Obj do
  begin
    Parent := Ojciec;
    Top := ODSTEP_V;
    Caption := s;
    Font.Size := ROZMIAR_CZCIONKI;
    if (s = '...') or (ojciec = Okno.Wyrazy) then
    begin
      dragMode := dmAutomatic;
      OnDragDrop := @Okno.LabelDragDrop;
      OnDragOver := @Okno.LabelDragOver;
    end;
    if s = '...' then
      Font.Bold := True;
  end;
  Ojciec.InsertComponent(Obj);
end;

procedure UtworzTLabele(A: SArray; Ojciec: TGroupBox);

  function KopiujString(s: string; k: integer): string;
  var
    tmp: string;
    i: integer;
  begin
    tmp := '';
    for i := 2 to Length(s) - k do
    begin
      tmp := tmp + s[i];
    end;
    KopiujString := tmp;
  end;

var
  i, k: integer;
  tmp: string;
  c: char;

begin
  for i := Low(A) to High(A) do
  begin
    k := 1;
    if (A[i][1] = DO_WSTAWIENIA) then
    begin
      Inc(IloscWolnychMiejsc);
      c := AnsiLastChar(A[i])^;
      if (c <> '<') then
        k := 2;
      tmp := KopiujString(A[i], k);
      DodajDoTablicy(tmp, Odpowiedzi);
      DodajSlowo(WOLNE_POLE, Ojciec);
      if (k = 2) then
        DodajSlowo(c, Ojciec);
    end
    else
      DodajSlowo(A[i], Ojciec);
  end;
  formatujTekst(Ojciec);
end;

{ Odpowiada za obsluge Drag and Drop TLabeli }
procedure TOkno.LabelDragDrop(Sender, Source: TObject; X, Y: integer);
var
  tmp1, tmp2: TLabel;
  s: string;
begin
  tmp1 := Sender as TLabel; // Gdzie
  tmp2 := Source as TLabel; // Skad
  if (tmp1.parent = Okno.Zdanie) and (Source <> Sender) then
  begin
    if tmp2.parent = Okno.Zdanie then
    begin
      if (tmp2.Font.Bold) then // Pogrubienie daje wyznacznik czy mozna tam wstawiac
      begin
        s := tmp2.Caption;
        tmp2.Caption := tmp1.Caption;
        tmp1.Caption := s;
      end;
    end
    else
    begin
      {Z wyrazow do zdania mozna tylko w wolne Pole wstawic, zeby wyraz nie znikl}
      if (tmp1.Caption = WOLNE_POLE) then
      begin
        Dec(IloscWolnychMiejsc);
        tmp1.Caption := tmp2.Caption;
        tmp2.Visible := False;
      end;
    end;
    FormatujTekst(Zdanie);
  end;
end;

procedure TOkno.LabelDragOver(Sender, Source: TObject; X, Y: integer;
  State: TDragState; var Accept: boolean);
begin
  accept := Source is TLabel;
end;

procedure ZaladujTest();

  procedure zaladuj(var A: SArray; ending: string);
  var
    i: integer;
    s, tmp: string;
    c: char;
  begin
    i := 0;
    while True do
    begin
      s := '';
      while (not eoln(f)) do
      begin
        Read(f, c);
        if c = ' ' then
          break;
        if c = '_' then // zamieniam podkreslenia na spacje
          c := ' ';
        s := s + c;
      end;
      if eoln(f) then
        Readln(f);
      if s = ending then
        break
      else
        DodajDoTablicy(s, A);
    end;
  end;

  procedure ZerujTablice();
  begin
    SetLength(Odpowiedzi, 0);
    SetLength(WyrazyZdania, 0);
    SetLength(WyrazyDoWstawienia, 0);
  end;

begin
  iloscWolnychMiejsc := 0;
  ZerujTablice();
  Zaladuj(WyrazyZdania, KONIEC_ZDANIA);
  Zaladuj(WyrazyDoWstawienia, KONIEC_TESTU);
  UtworzTlabele(WyrazyZdania, Okno.Zdanie);
  UtworzTlabele(WyrazyDoWstawienia, Okno.Wyrazy);
end;


procedure SprawdzPoprawnosc();
var
  i, j: integer;
  tmp: TLabel;
begin
  j := 0;
  for i := 0 to Okno.Zdanie.ComponentCount - 1 do
  begin
    tmp := Okno.Zdanie.Components[i] as TLabel;
    if tmp.Font.Bold = True then
    begin
      if Odpowiedzi[j] = tmp.Caption then
      begin
        tmp.Color := clLime;
        Inc(IlePoprawnych);
      end
      else
      begin
        tmp.Color := clRed;
        Inc(IleBlednych);
      end;
      Inc(j);
    end;
  end;
end;

procedure DodajDoTablicy(s: string; var A: SArray);
var
  k: integer;
begin
  k := Length(A) + 1;
  SetLength(A, k);
  A[k - 1] := s;
end;

end.
