unit ControllerFabricante;

interface

uses
 DB, DBClient, System.Classes, ControllerBase,  EnumEntity;

type
  TControllerFabricante = class(TControllerBase)
  public

  end;

implementation


initialization RegisterClass(TControllerFabricante);
finalization UnRegisterClass(TControllerFabricante);

end.
