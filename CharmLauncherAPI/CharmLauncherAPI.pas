unit CharmLauncherAPI;

type
  TLauncher = class
    GameDirectory: string;
    Logging: Boolean;
    TLaunchInfo = record
      JavaPath: string[500];
      Version: string[100];
    end;
  end;

interface

implementation

end.
