unit CharmLauncherAPI;

interface


uses
System.SysUtils;


type
  TLaunchInfo = record
    JavaPath: string[255];
    Version: string[100];
  end;
  TLauncher = class(TObject)
    Logging: Boolean;
  private
    FDirectory: string;
  public
    constructor Create(const Directory: string);
    property Directory: string read FDirectory;
  end;



implementation



{ TLauncher }

constructor TLauncher.Create(const Directory: string);
begin
  SetCurrentDir(Directory);
end;



end.
