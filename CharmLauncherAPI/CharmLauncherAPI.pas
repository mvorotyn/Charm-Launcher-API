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


  TLaunchInfo = record
    JavaPath: string[255];
    Version: string[100];
  end;

  TLauncher = class(TObject)
    Logging: Boolean;
  private
    FGameDirectory: string;
    function GetVersions: TStringList;
    Function DetectRam : integer;
  public
    constructor Create(const GameDirectory: string);
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

end.
