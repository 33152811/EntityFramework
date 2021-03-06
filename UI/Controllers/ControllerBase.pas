unit ControllerBase;

interface

uses
  System.Classes, Vcl.Controls, DBClient, Forms, Dialogs, Vcl.Grids, DB,
  Winapi.Windows, Context, InterfaceController, Vcl.DBGrids, Variants,
  Vcl.StdCtrls, EntityFramework, EnumEntity, Vcl.DBCtrls, Vcl.ExtCtrls,
  InterfaceService; //<<-- EntityFramework
                    //Est� aqui temporariamente
                    //devido o metodo LoadLookUp
type
  {$M+}
  TControllerBase = class(TInterfacedPersistent, IControllerBase)
  private
    FRefCount: Integer;
    procedure SetContener(const Value: TComponent);
    function GetContener: TComponent;
  protected
    FState: TEntityState;
    FContener: TComponent;
  //EntityDataSet: TClientDataSet;
    Service:IServiceBase;
    procedure CleanComponents;
    procedure UpdateState(const ValueState: TEntityState);
  public
    constructor Create( pService:IServiceBase );virtual;
    function Load(iId:Integer; Fields: string = '' ): TDataSet; virtual;
    procedure Refresh; virtual;
    procedure Read; virtual;
    procedure Insert(E: TEnumEntities); virtual;
    procedure Edit; virtual;
    procedure Delete; virtual;
    procedure Post; virtual;
    procedure Cancel; virtual;
    procedure Apply; virtual;
    procedure EntityToDBGrid(Grid: TDBGrid);
    procedure LoadLookUp(DBLookupComboBox: TDBLookupComboBox ; DataSource: TDataSource; E:TEnumEntities);
    property State: TEntityState read FState write FState;
    property Contener: TComponent read GetContener write SetContener;

    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;
  {$M-}

implementation

{ TControllerClient }

uses  FactoryEntity, ViewBase, EntityConnection, FactoryConnection, FactoryRepository, AutoMapper,
  FactoryService;

constructor TControllerBase.Create(pService:IServiceBase);
begin
  Inherited Create;
  Service   := pService;
end;

procedure TControllerBase.EntityToDBGrid(Grid: TDBGrid);
var
  Field: string;
begin
  if Grid.Columns.Count = 0 then
  begin
    Grid.Columns.Clear;
    for Field in Service.FieldList do
      Grid.Columns.Add.FieldName := Field;
  end;
end;

function TControllerBase.GetContener: TComponent;
begin
   result := FContener;
end;

procedure TControllerBase.CleanComponents;
var
  I: Integer;
begin
  with FContener as TComponent do
  begin
    for I := 0 to ComponentCount - 1 do
    begin
       if Components[I] is TEdit then
         (Components[I] as TEdit).text := ''
       else
       if Components[I] is TCombobox then
         (Components[I] as TCombobox).text := ''
       else
       if Components[I] is TMemo then
         (Components[I] as TMemo).clear
       else
       if Components[I] is TRadioGroup then
         (Components[I] as TRadioGroup).ItemIndex:= -1
       else
       if Components[I] is TCheckBox then
         (Components[I] as TCheckBox).Checked:= false;
    end;
  end;
end;

function TControllerBase.Load(iId:Integer; Fields: string = ''): TDataSet;
begin
  result := Service.Load( iId , Fields);
end;

procedure TControllerBase.Insert(E: TEnumEntities);
begin
  CleanComponents;
  Service.InitEntity(FContener);
  UpdateState(esInsert);
end;

procedure TControllerBase.Post;
begin
  Service.InputEntity(FContener);
  Service.Post( State );
  UpdateState(esBrowser);
  with FContener as TFormViewBase do
  begin
    if AutoApplyUpdate then
    begin
       Apply;
       pgPrincipal.ActivePageIndex:= 0;
    end;
  end;
end;

procedure TControllerBase.Cancel;
begin
  Read;
  UpdateState(esBrowser);
end;

procedure TControllerBase.Read;
begin
  Service.ReadEntity(FContener);
end;

procedure TControllerBase.Edit;
begin
  Read;
  UpdateState(esEdit);
end;

procedure TControllerBase.Delete;
begin
  if Application.MessageBox('Deseja realmente excluir ?',
  'Excluir',MB_YESNO+MB_ICONQUESTION) = ID_YES then
  begin
    Service.Delete;
    Apply;
  end;
end;

procedure TControllerBase.Apply;
begin
  Service.Persist;
  //Refresh;
end;

procedure TControllerBase.Refresh;
begin
   UpdateState(esBrowser);
   Service.RefresData;
end;

procedure TControllerBase.SetContener(const Value: TComponent);
begin
  FContener := Value;
end;

procedure TControllerBase.UpdateState(const ValueState: TEntityState);
var
  Modified:boolean;
begin
  if FContener is TFormViewBase then
  begin
    with FContener as TFormViewBase do
    begin
      Modified := ValueState in [esInsert, esEdit];

      btnNew.enabled    := not(Modified);
      btnEdit.enabled   := not(Modified);
      btnRemove.enabled := not(Modified);
      btnCancel.enabled := Modified;
      btnPost.enabled   := Modified;
      if ValueState <> esBrowser then
         pgPrincipal.ActivePageIndex := 1;
      btnApply.enabled := true;
    end;
    FState := ValueState;
  end;
end;

procedure TControllerBase.LoadLookUp(DBLookupComboBox: TDBLookupComboBox;
                                     DataSource:TDataSource;
                                     E :TEnumEntities);
var
  LookUpContext: TContext;
  LookUpDataSet: TClientDataSet;
begin
  try
     LookUpContext:= TContext.Create(E);
     if LookUpContext.Connection <> nil then
     begin
       LookUpDataSet := TClientDataSet.Create(application);
       LookUpDataSet.data := LookUpContext.GetData( From( TFactoryEntity.GetEntity( E ) ).
                                                    Select([ DBLookupComboBox.ListField ,
                                                             DBLookupComboBox.KeyField ]) );
       DataSource.Dataset  := LookUpDataSet;
     end;
  finally
    LookUpContext.Free;
  end;
end;


function TControllerBase._AddRef: Integer;
begin
  Result := inherited _AddRef;
  InterlockedIncrement(FRefCount);
end;

function TControllerBase._Release: Integer;
begin
  Result := inherited _Release;
  InterlockedDecrement(FRefCount);
  if FRefCount <=0 then
    Free;
end;


end.

