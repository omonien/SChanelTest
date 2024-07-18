program SChannelTest;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Tests.SChannel in 'Tests.SChannel.pas';

begin
  try
    TTestSChannel.RunAll;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  readln;
end.
