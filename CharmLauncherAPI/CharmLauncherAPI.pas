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
    function JsonParse(RawJsonFile: string): FJSONObject;
    function JsonExtractLibs(SourceObject: FJSONObject): string;
    function JsonExtractMainClass(SourceObject: FJSONObject): string;
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


function TLauncher.JsonParse(RawJsonFile: String): FJSONObject;
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


function TLauncher.JsonExtractLibs(SourceObject: FJSONObject): string;
var
  ParsedLibraries: TStringList;
  JsonArray: TJSONArray;
  i, h, magic: integer;
  current_str : string;
  NeedtoReplaceDot, first_delimiter_allow: Boolean;
  first_delimiter_symbol,  second_delimiter_symbol: integer ;
  base, base_num: string;
begin
  ParsedLibraries:=TStringList.create;
  JsonArray:=TJSONArray.Create;
  JsonArray:=SourceObject.Get('libraries').JsonValue as TJsonArray;
  for I := 0 to JsonArray.Size-1 do begin
     ParsedLibraries.Add((JsonArray.Get(i) as TJSONObject).Get('name').JsonValue.Value);
  end;

  for I := 0 to ParsedLibraries.Count-1 do
  begin
    NeedtoReplaceDot:=True;

    current_str:=ParsedLibraries.Strings[i];
    for  h := 0 to Length(current_str)-1 do
      begin
        if NeedtoReplaceDot=True then
          if current_str[h] = '.' then
            current_str[h] := '\' ;


        if current_str[h] = ':' then
        begin
          current_str[h] := '\';

          if (first_delimiter_allow=True) then
          begin
            first_delimiter_symbol := h;
            first_delimiter_allow:=False;
          end;


          if not (first_delimiter_symbol = h) then
          begin
            second_delimiter_symbol := h;
            magic:= length(current_str) - second_delimiter_symbol;
            base:= copy(current_str, first_delimiter_symbol + 1, length(current_str) - first_delimiter_symbol - magic - 1);
            base_num:=copy(current_str, second_delimiter_symbol + 1, length(current_str) - second_delimiter_symbol);
            current_str:='libraries\' + current_str + '\' + base + '-' + base_num + '.jar;';

            first_delimiter_allow:=True;
          end;

          NeedtoReplaceDot:=False;
        end;

      end;

    ParsedLibraries.Strings[i]:=current_str;
  end;

  Result:='';
  for i := 0 to ParsedLibraries.Count-1 do
  begin
    Result:=Result + ParsedLibraries.Strings[i];
  end;

end;

function TLauncher.JsonExtractMainClass(SourceObject: FJSONObject): string;
var
  Enum: TStringList;
  i: integer;
begin
  Enum:=TstringList.Create;
  for i := 0 to SourceObject.Size-1 do
    Enum.Add((SourceObject.Get(i)).JsonString.Value);

  for i := 0 to Enum.Count-1 do
  begin
    if Enum.Strings[i]='mainClass' then
      Result:=SourceObject.Get('mainClass').JsonValue.Value
    else
      Result:='';
  end;

end;

end.
