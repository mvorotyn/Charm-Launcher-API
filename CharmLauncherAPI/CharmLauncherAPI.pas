unit CharmLauncherAPI;

interface


uses
System.SysUtils, System.Classes;


type
  TLaunchInfo = record
    JavaPath: string[255];
    Version: string[100];
  end;

  TLauncher = class(TObject)
    Logging: Boolean;
  private
    FGameDirectory: string;
    function GetVersions: TStringList;
  public
    constructor Create(const GameDirectory: string);
    property GameDirectory: string read FGameDirectory;
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


end.
