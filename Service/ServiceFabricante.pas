unit ServiceFabricante;

interface

uses
System.Classes, ServiceBase, InterfaceServiceFabricante, EnumEntity;

type
  TServiceFabricante=class( TServiceBase , IServiceFabricante)
  public

  end;

implementation

{ ServiceFabricante }

initialization RegisterClass(TServiceFabricante);
finalization UnRegisterClass(TServiceFabricante);

end.
