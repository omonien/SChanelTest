unit Tests.SChannel;

interface

uses
  System.Classes, System.SysUtils,
  IdHTTP,
  Execute.IdSSLSChannel, Execute.SChannel;

type
  TTestSChannel = class(TObject)
  private
    class var FLock: TObject;
  public
    procedure Single;
    procedure Multi;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Log(const AMessage: string);
    class procedure RunAll;
  end;

const
  MAX = 100;
  TEST_URL = 'example.com';

implementation

uses
  System.Threading;

{ TTestSChannel }

class constructor TTestSChannel.Create;
begin
  FLock := TObject.Create;
end;

class destructor TTestSChannel.Destroy;
begin
  FreeAndNil(FLock);
end;

class procedure TTestSChannel.Log(const AMessage: string);
begin
  TMonitor.Enter(FLock);
  try
    var
    LThreadId := '[T' + TThread.Current.ThreadID.ToString + ']';
    var
    LTime := FormatDateTime('hh:nn:ss,zzz', now);
    Writeln(LTime + ' ' + LThreadId + ' ' + AMessage);
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TTestSChannel.Multi;

var
  LTask: ITask;
  LAllTasks: TArray<ITask>;
begin
  Log('Multi Request ...');
  Log('Number of tests ' + MAX.ToString);
  SetLength(LAllTasks, MAX);

  for var i := 0 to MAX - 1 do
  begin
    LTask := TTask.Run(
      procedure
      begin
        Single;
      end);
    LAllTasks[i] := LTask;
  end;

  TTask.WaitForAll(LAllTasks);
end;

class procedure TTestSChannel.RunAll;
begin
  Log('SChannel  IO Handler Test');
  Log('Running all tests...');
  Log('Testing "' + TEST_URL + '"');

  var
  LTest := TTestSChannel.Create;
  try
    try
      LTest.Single;
      LTest.Multi;
      Log('All tests passed.');
    except
      on E: Exception do
      begin
        Log('Test failed: ' + E.Message);
      end;
    end;
  finally
    FreeAndNil(LTest);
  end;
end;

procedure TTestSChannel.Single;

var
  LHttp: TIdHTTP;
  LSChannelIOHandler: TIdSSLIOHandlerSocketSChannel;
  LResponseHttp: string;
  LResponseHttps: string;

begin
  Log('Single Request ...');
  try
    LHttp := nil;
    LSChannelIOHandler := nil;
    try
      LHttp := TIdHTTP.Create;
      // First, try HTTP
      LResponseHttp := LHttp.Get('http://example.com');
      Assert(LResponseHttp.Contains('<h1>Example Domain</h1>')); //This should pass, as that header has been there forever

      // Now try HTTPS
      // Setup SChannel IO handler
      LSChannelIOHandler := TIdSSLIOHandlerSocketSChannel.Create(nil);
      LHttp.IOHandler := LSChannelIOHandler;

      LResponseHttps := LHttp.Get('https://example.com');
      Assert(LResponseHttps.Contains('<h1>Example Domain</h1>'));
      Assert(LResponseHttp = LResponseHttps); // HTTP and HTTPS responses should be identical
      Log('passed with ' + Length(LResponseHttp).ToString +' chars received');
    finally
      FreeAndNil(LSChannelIOHandler);
      FreeAndNil(LHttp);
    end;
  except
    on E: Exception do
    begin
      Log('Test failed ' + E.Message);
    end;
  end;
end;

end.
