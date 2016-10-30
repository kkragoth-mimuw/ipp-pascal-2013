program laboratorium;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, testyjezykowe;

{$R *.res}


begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TOkno, Okno);
  Application.Run;
end.

