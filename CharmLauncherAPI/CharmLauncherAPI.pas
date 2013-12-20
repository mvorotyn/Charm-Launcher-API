unit CharmLauncherAPI;

interface


uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Forms, Vcl.Dialogs, DBXJSON;


type
  MEMORYSTATUSEX = record
    dwLength: DWORD;
    dwMemoryLoad: DWORD;
    ullTotalPhys: Int64;
    ullAvailPhys: Int64;
    ullTotalPageFile: Int64;
    ullAvailPageFile: Int64;
    ullTotalVirtual: Int64;
    ullAvailVirtual: Int64;
    ullAvailExtendedVirtual: Int64;
  end;

  FJSONObject = TJSONObject;

  TLaunchInfo = record
    JavaPath: string[255];
    Version: string[100];
    GameLibs: string[255];
    GarbageCollectorEnabled: Boolean;
    MaxHeapSizeGb: string[2];
    auth_player_name: string[255];
    auth_uuid: string[255];
    auth_access_token: string[255];
    twitch_access_token: string[255];
    assets_index_name:  string[20];
    assets_root: string[100];

  end;

  TLauncher = class(TObject)
    Logging: Boolean;
  private
    FGameDirectory: string;
    function GetVersions: TStringList;
    Function DetectRam : integer;
  public
    constructor Create(const GameDirectory: string);
    function ParseJson(RawJsonFile: string): FJSONObject;
    function LaunchGame(LaunchInfo: TLaunchInfo): integer;
    property GameDirectory: string read FGameDirectory;
    property AvailableRAM: integer read DetectRAM;
  published
    property Versions: TStringList read GetVersions;
  end;


implementation



{ TLauncher }

constructor TLauncher.Create(const GameDirectory: string);
begin

  FGameDirectory:=GameDirectory;
  SetCurrentDir(GameDirectory);
end;


function TLauncher.LaunchGame(LaunchInfo: TLaunchInfo): integer;
begin

end;



function TLauncher.GetVersions: TStringList;
  var
  searchResult : TSearchRec;
  i : integer;
begin
  Result:=TStringList.Create;

  if (FGameDirectory = '') then
    raise Exception.Create('Wrong Game Directory');

  if FGameDirectory[length(FGameDirectory)] = '\' then
    FGameDirectory:=Copy(FGameDirectory, 1, length(FGameDirectory)-1);

  if FindFirst(FGameDirectory + '\versions\' + '*', faDirectory, searchResult) = 0 then
  begin
    repeat
      if (searchResult.attr and faDirectory) = faDirectory
      then Result.add(searchResult.Name);
    until FindNext(searchResult) <> 0;
    FindClose(searchResult);

    //Clearing Results
    Result.Delete(0);
    Result.Delete(0);

    if Result.Count > 0 then
    begin
      for i := 0 to Result.Count-1 do
      begin
        if not FileExists(FGameDirectory + '\versions\' + Result[i] + '\' + Result[i] + '.json') then
          Result.Delete(i);
       end;
    end else
      raise Exception.Create('No versions installed!');
  end;

end;


function TLauncher.DetectRam : integer;
var
  MemoryInfo : _MEMORYSTATUSEX;
  TotalRAM : integer;
begin
  MemoryInfo.dwLength := SizeOf(MEMORYSTATUSEX) ;
  GlobalMemoryStatusEx(MemoryInfo);
  TotalRAM := trunc (MemoryInfo.ullTotalPhys div 1024 / 1024);
  Result := TotalRAM;
end;


function TLauncher.ParseJson(RawJsonFile: String): FJSONObject;
Var
  RawJSON: TStringList;
  ParsedObject: FJSONObject;
begin
  if not FileExists(RawJsonFile) then
    raise Exception.Create('JSON file does not exist');


  RawJSON:= TStringList.Create;
try
  RawJson.LoadFromFile(RawJsonFile);
  ParsedObject:=FJSONObject.Create;
  ParsedObject:=TJSONObject.ParseJSONValue( RawJSON.Text) as TJSONObject;
  if Assigned(ParsedObject) then
    Result:=ParsedObject
  else
    raise Exception.Create('JSON file corrupted');
finally
  RawJSON.Free;
end;

end;

end.
