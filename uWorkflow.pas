unit uWorkflow;

interface

uses
System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.ExtCtrls,
  // generique
  System.Generics.Collections, System.Math,
  // dataBase
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageBin, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client
  ;

const
  KWENT = 'DIA_WF_ENTITE'; // table modèle
  KWFM = 'DIA_WF_MODEL';         // table modèle
  KWFMS = 'DIA_WF_MODEL_STEP';  // table étapes du modèle  : step
  KWDATA = 'DIA_WF';  // table étapes du modèle  : step


type

  TWFDataMode = (wdmFileJSON, wdmFileBin , wdmDB);
  TWFStepKind = (wsInit, wsAction, wsTest, wsInform, wsFinal);
  TWFOpp = (wo_, woAND, woOR);

  TWorkFlow = class(TObject)
  private
    FEntity: TStringList;
    FDataMode: TWFDataMode;

    FWentite : TFDMemTable;
    FWModel : TFDMemTable;
    FWModelStep  : TFDMemTable;
    FWData    : TFDMemTable;

    procedure SetEntity(const Value: TStringList);
    procedure SetDataMode(const Value: TWFDataMode);
    procedure SetWData(const Value: TFDMemTable);
    procedure SetModel(const Value: TFDMemTable);
    procedure SetModelStep(const Value: TFDMemTable);
    function  CreateDataSets : string;

  public
    constructor Create(aDataMode : TWFDataMode ; aFilePath : string = ''); overload;
    destructor Destroy; override;

    procedure loadPatternFromfile(aFileName : string);
    procedure savePatternToFile(afileName : string);
    procedure loadPatternFromDB;
    procedure savePatternToDB;

  published
    property Entity : TStringList read FEntity write SetEntity;
    property DataMode : TWFDataMode read FDataMode write SetDataMode;

    property Model  : TFDMemTable read FWModel write SetModel;
    property ModelStep : TFDMemTable read FWModelStep write SetModelStep;
    property Data   : TFDMemTable read FWData write SetWData;

  end;

  TDesignWorkFlow = class;

  TDesignWFStep = class(TShape)
  private
    FLevel: integer;
    FToAction: string;
    FStep: integer;
    FGroup: string;
    FOperation: TWFOpp;
    FPadding: integer;
    FContainer: TComponent;
    FstepKind: TWFStepKind;
    procedure SetGroup(const Value: string);
    procedure SetLevel(const Value: integer);
    procedure SetToAction(const Value: string);
    procedure SetStep(const Value: integer);
    procedure SetOperation(const Value: TWFOpp);
    procedure ShowStep;
    procedure SetPadding(const Value: integer);
    procedure SetContainer(const Value: TComponent);
    procedure SetstepKind(const Value: TWFStepKind);
  public
    Constructor Create(aOwner : Tcomponent ; aStepKind: TWFStepKind ; aPadding : integer ; aStep : integer ; aLevel : Integer ; aOp : TWFOpp ; aGroup : string ; aToAction : string); overload;
    Destructor Destroy; override;

  published
    property stepKind : TWFStepKind read FstepKind write SetstepKind;
    property Padding : integer read FPadding write SetPadding;
    property Level : integer read FLevel write SetLevel;
    property Step  : integer read FStep write SetStep;
    property Operation  : TWFOpp read FOperation write SetOperation;
    property Group : string read FGroup write SetGroup;
    property ToAction : string read FToAction write SetToAction;
    property Container : TComponent read FContainer write SetContainer;
  end;

  TDesignWorkFlow = class(TPanel)
  private
    FSteps : TList<TDesignWFStep>;
    FEntities : TList<TShape>;
    FPadding : integer;
    Fcontainer: TWorkFlow;
    FColumnwidth: integer;
    procedure Setcontainer(const Value: TWorkFlow);
    procedure SetPadding(const Value: integer);

    procedure ShowEntityColumns;
    procedure SetColumnwidth(const Value: integer);

  public
    constructor Create(AOwner: TComponent ; aContainer : TWorkFlow = nil ; aWorkFlowID : integer = -1); overload;
    destructor Destroy; override;

    function GetMaxLevel : integer;

    procedure AddStep(aStepKind : TWFStepKind ; aStep : integer ; aLevel : integer; aOp : TWFOpp);


  published
    property container : TWorkFlow read Fcontainer write Setcontainer;
    property Padding : integer read FPadding write SetPadding;
    property Columnwidth : integer read FColumnwidth write SetColumnwidth;
  end;

var
  ProcessWorkFlow : TWorkFlow;

implementation


{ TWorkFlow }
{$region 'TWorkFlow Process ************************************'}
constructor TWorkFlow.Create(aDataMode : TWFDataMode ; aFilePath : string = '');
begin
  inherited Create;

  FEntity := TStringList.Create;
  FDataMode := aDataMode;
  if FDataMode = TWFDataMode.wdmDB then
  begin

  end
  else
  begin

    FWentite    := TFDMemTable.Create(nil);
    FWModel     := TFDMemTable.Create(nil);
    FWModelStep := TFDMemTable.Create(nil);
    FWData      := TFDMemTable.Create(nil);

    CreateDatasets;

  end;

end;

destructor TWorkFlow.Destroy;
begin

  inherited;
end;

function TWorkFlow.CreateDataSets : string;
var
  vSQL : string;
begin
  if FDataMode = TWFDataMode.wdmDB then
  begin
    vSQL :=
    'CREATE TABLE ' + KWFM + ' ('+
    ' WFE_ID INTEGER AUTOINCREMENT PRIMARY, '+
    ' WFE_NAME VARCHAR(50), '+
    ' WFE_PROFIL VARCHAR(30), '+          // un groupe de personne
    ' WFE_USER_ID INTEGER );'+ #$D#$A+    // une seule personne

    'CREATE TABLE ' + KWFM + ' ('+
    ' WF_ID INTEGER AUTOINCREMENT PRIMARY, '+
    ' WF_GROUP VARCHAR(30), '+
    ' WF_NAME VARCHAR(50), '+
    ' WF_ENTITYLIST VARCHAR(1024), '+  // ENTITELIST Entite1=couleur,Entite2=couleur,Entite3=couleur,Entite4=couleur,
    ' WF_ORDRE );'+ #$D#$A+

    'CREATE TABLE ' + KWFMS + ' ('+
    ' WFS_ID INTEGER AUTOINCREMENT PRIMARY, '+
    ' WFS_WF_ID INTEGER, '+
    ' WFS_TYPE VARCHAR(30), /* INIT, ACTION, DECISION, INFO, FINAL */ '+
    ' WFS_STEP INTEGER, '+
    ' WFS_ENTITY_ID INTEGER, '+
    ' WFS_ENTITY VARCHAR(100), '+
    ' WFS_NAME VARCHAR(100), '+
    ' WFS_OPERATION VARCHAR(100), '+
    ' WFS_NAME VARCHAR(100), '+
    ' WFS_TRIGGER_IN VARCHAR(8192), '+
    ' WFS_ACTION VARCHAR(8192), '+
    ' WFS_TRIGGER_OUT VARCHAR(8192), '+
    ' );'+ #$D#$A+

    KWENT

  end
  else
  begin

    FWModel.FieldDefs.Add('WF_ID', TFieldType.ftAutoInc, 0);
    FWModel.FieldDefs.Add('WF_GROUP', TFieldType.ftString, 30);
    FWModel.FieldDefs.Add('WF_NAME', TFieldType.ftString, 50);
    FWModel.FieldDefs.Add('WF_ORDRE', TFieldType.ftInteger, 0);

    FWModel.CreateDataSet;


    FWModelStep.FieldDefs.Add('WFS_ID', TFieldType.ftAutoInc, 0);
    FWModelStep.FieldDefs.Add('WFS_WF_ID', TFieldType.ftInteger, 30);
    FWModelStep.FieldDefs.Add('WFS_TYPE',  TFieldType.ftString, 30);      //  INIT, ACTION, DECISION, INFO, FINAL
    FWModelStep.FieldDefs.Add('WFS_STEP',  TFieldType.ftInteger, 0);
    FWModelStep.FieldDefs.Add('WFS_ENTITY_ID', TFieldType.ftInteger, 50); // destinataire de l'information
    FWModelStep.FieldDefs.Add('WFS_ENTITY', TFieldType.ftString, 100);
    FWModelStep.FieldDefs.Add('WFS_NAME',   TFieldType.ftString, 50);
    FWModelStep.FieldDefs.Add('WFS_OPERATION', TFieldType.ftString, 8192);
    FWModelStep.FieldDefs.Add('WFS_TRIGGER_IN', TFieldType.ftString, 8192);
    FWModelStep.FieldDefs.Add('WFS_ACTION',     TFieldType.ftString, 8192);
    FWModelStep.FieldDefs.Add('WFS_TRIGGER_OUT', TFieldType.ftString, 8192);

    FWModelStep.CreateDataSet;


    FWModelStep.FieldDefs.Add('WFD_ID', TFieldType.ftAutoInc, 0);
    FWModelStep.FieldDefs.Add('WFD_WF_ID', TFieldType.ftInteger, 0);
    FWModelStep.FieldDefs.Add('WFD_WFS_ID', TFieldType.ftInteger, 0);
    FWModelStep.FieldDefs.Add('WFD_ETAT', TFieldType.ftString, 50);     // attente validation ou action utilisateur
    FWModelStep.FieldDefs.Add('WFD_KEYNAME', TFieldType.ftString, 50);  // nom du champ  ( N° commande, N° facture, etc...)
    FWModelStep.FieldDefs.Add('WFD_KEYVALUE', TFieldType.ftString, 50); // valeur clé (N° commande, N° facture, etc...)
    FWModelStep.FieldDefs.Add('WFD_INLINE_DATA', TFieldType.ftString, 8192);


    FWModelStep.CreateDataSet;


  end;

end;

procedure TWorkFlow.loadPatternFromDB;
begin
  //

end;

procedure TWorkFlow.loadPatternFromfile(aFileName: string);
begin
  //
  aFileName := ChangeFileExt(aFileName, '.pwf');
  if FileExists(aFileName) then
  begin
   if FDataMode = TWFDataMode.wdmFileJSON then
   begin
      FWModel.LoadFromFile(aFileName, TFDStorageFormat.sfJSON);
      aFileName := ChangeFileExt(aFileName, '.pwfs');
      if FileExists(aFileName) then
        FWModelStep.LoadFromFile(aFileName, TFDStorageFormat.sfJSON)
      else
        raise Exception.Create('File ' + aFileName + ' not exist');

   end
   else if FDataMode = TWFDataMode.wdmFileJSON then
   begin
      FWModel.LoadFromFile(aFileName, TFDStorageFormat.sfBinary);
      aFileName := ChangeFileExt(aFileName, '.pwfs');
      if FileExists(aFileName) then
        FWModelStep.LoadFromFile(aFileName, TFDStorageFormat.sfBinary)
      else
        raise Exception.Create('File ' + aFileName + ' not exist');
   end
   else
     raise Exception.Create('Invalid file format');

  end;

end;

procedure TWorkFlow.savePatternToDB;
begin
  //

end;

procedure TWorkFlow.savePatternToFile(afileName: string);
begin
  //
  if FileExists(aFileName) then
  begin
   if FDataMode = TWFDataMode.wdmFileJSON then
   begin
      FWModel.SaveToFile(aFileName, TFDStorageFormat.sfJSON);
      aFileName := ChangeFileExt(aFileName, '.pwfs');
      FWModelStep.SaveToFile(aFileName, TFDStorageFormat.sfJSON);
   end
   else if FDataMode = TWFDataMode.wdmFileJSON then
   begin
      FWModel.SaveToFile(aFileName, TFDStorageFormat.sfBinary);
      aFileName := ChangeFileExt(aFileName, '.pwfs');
      FWModelStep.SaveToFile(aFileName, TFDStorageFormat.sfJSON);
   end
   else
     raise Exception.Create('Invalid file format');

  end;

end;

procedure TWorkFlow.SetDataMode(const Value: TWFDataMode);
begin
  FDataMode := Value;
end;

procedure TWorkFlow.SetEntity(const Value: TStringList);
begin
  FEntity := Value;
end;

procedure TWorkFlow.SetWData(const Value: TFDMemTable);
begin
  FWData := Value;
end;

procedure TWorkFlow.SetModel(const Value: TFDMemTable);
begin
  FWModel := Value;
end;

procedure TWorkFlow.SetModelStep(const Value: TFDMemTable);
begin
  FWModelStep := Value;
end;

{$endregion}   // TWorkFlow


{ TDesignWorkFlow }
{$region 'TDesignWorkFlow Process ************************************'}

function TDesignWorkFlow.GetMaxLevel : integer;
var
  i : integer;
begin
  result := 0;
  i := 0;
  while i < FSteps.count do
  begin
    result := max(result, FSteps[i].Level);
    inc(i);
  end;

end;


procedure TDesignWorkFlow.SetColumnwidth(const Value: integer);
begin
  FColumnwidth := Value;
end;

procedure TDesignWorkFlow.Setcontainer(const Value: TWorkFlow);
begin
  Fcontainer := Value;
end;

procedure TDesignWorkFlow.SetPadding(const Value: integer);
begin
  FPadding := Value;
end;

procedure TDesignWorkFlow.ShowEntityColumns;
var
  i : integer;
  vShape : TShape;
//  vText : TStaticText;
begin
  //

  i := 0;
  while i < TWorkFlow(FContainer).Entity.Count do
  begin

    vShape := Tshape.Create(self);
    vShape.Parent := self;
    vshape.Align := Talign.alLeft;
    vshape.Width := self.Columnwidth;
    vshape.Brush.Color := StrToIntDef(TWorkFlow(FContainer).Entity.ValueFromIndex[i], $ffffff);

    //vText

    FEntities.Add(vShape);

    inc(i);
  end;

end;

procedure TDesignWorkFlow.AddStep(aStepKind: TWFStepKind; aStep, aLevel: integer; aOp: TWFOpp);
var
  vShape : TDesignWFStep;
  vHeight : integer;
begin

  vshape := TDesignWFStep.Create(Self, aStepKind, FPadding, aStep, aLevel, aOp, '', '');
  FSteps.Add(vshape);

end;

constructor TDesignWorkFlow.Create(AOwner: TComponent ; aContainer : TWorkFlow = nil ; aWorkFlowID : integer = -1);
begin
  inherited Create(AOwner);


  self.container := aContainer;
  self.Parent := TWinControl(AOwner);

  FSteps := TList<TDesignWFStep>.Create;
  FPadding := 15;

  // créer les Parties prenantes
  ColumnWidth := 120;
  FEntities := TList<TShape>.create;
  ShowEntityColumns;

  // TODO : charger le workflowID



end;

destructor TDesignWorkFlow.Destroy;
begin

  while FSteps.Count > 0 do
    FSteps.Delete(0);

  FSteps.Free;

  inherited;
end;

{$endregion}   // TDesignWorkFlow

{ TDesignWFStep }
{$region 'TDesignWFStep Process ************************************'}

constructor TDesignWFStep.Create(aOwner: Tcomponent ;  aStepKind: TWFStepKind ; aPadding, aStep, aLevel: Integer; aOp: TWFOpp; aGroup, aToAction: string);
begin
  inherited Create(aOwner);

  FStepKind := aStepKind;
  FPadding := aPadding;
  FStep := aStep;
  FLevel := aLevel;
  FOperation := aOp;
  FGroup := aGroup;
  FToAction := aToAction;
  FContainer := aOwner;

  ShowStep;
end;


destructor TDesignWFStep.Destroy;
begin
  //self.Free;

  Inherited;
end;

procedure TDesignWFStep.ShowStep;
var
  vHeight : integer;
begin

  self.Parent := TWinControl(FContainer);
  vHeight := FPadding + 50 ;

  case FStepKind of
    TWFStepKind.wsInit :
    begin
      self.Shape := TShapeType.stRectangle;
      self.Brush.Color := clSkyblue;
      self.Pen.Color := clWebCornFlowerBlue;
      self.Height := 50;
      self.width := 80;
//      vShape.Left := (FPadding + vShape.width) * aLevel;
//      vShape.Top := (FPadding + vShape.Height ) * aStep;
    end;

    TWFStepKind.wsAction :
    begin
      self.Shape := TShapeType.stRoundRect;
      self.Brush.Color := clWhite;
      self.Pen.Color := clblack;
      self.Height := 50;
      self.width := 80;
//      vShape.Left := (FPadding + vShape.width) * aLevel;
//      vShape.Top := (FPadding + vShape.Height ) * aStep;
    end;

    TWFStepKind.wsTest :
    begin
      self.Shape := TShapeType.stRectangle;
      self.Brush.Color := clblack;
      self.Pen.Color := clblack;
      self.Height := 8;
      self.width := TDesignWorkFlow(FContainer).GetMaxLevel * 80;

      TDesignWorkFlow(FContainer).GetMaxLevel

//      vShape.Left := (FPadding + vShape.width) * aLevel;
//      vShape.Top := (FPadding + vShape.Height ) * aStep;
    end;

    TWFStepKind.wsInform :
    begin
      self.Shape := TShapeType.stRectangle;
      self.Brush.Color := clSilver;
      self.Pen.Color := clGray;
      self.Height := 50;
      self.width := 50;
//      vShape.Left := (FPadding + vShape.width) * aLevel;
//      vShape.Top := (FPadding + vShape.Height ) * aStep;
    end;

    TWFStepKind.wsFinal :
    begin
      self.Shape := TShapeType.stCircle;
      self.Brush.Color := clMoneyGreen;
      self.Pen.Color := clGreen;
      self.Height := 50;
      self.width := 50;
//      vShape.Left := (FPadding + vShape.width) * aLevel;
//      vShape.Top := (FPadding + vShape.Height ) * aStep;
    end;


  end;

  self.Left := (FPadding + TDesignWorkFlow(FContainer).Columnwidth) * (1 + FLevel);
  self.Top := (vHeight) * (1 + FStep);

end;


procedure TDesignWFStep.SetContainer(const Value: TComponent);
begin
  FContainer := Value;
end;

procedure TDesignWFStep.SetGroup(const Value: string);
begin
  FGroup := Value;
end;

procedure TDesignWFStep.SetLevel(const Value: integer);
begin
  FLevel := Value;
end;

procedure TDesignWFStep.SetOperation(const Value: TWFOpp);
begin
  FOperation := Value;
end;

procedure TDesignWFStep.SetPadding(const Value: integer);
begin
  FPadding := Value;
end;

procedure TDesignWFStep.SetToAction(const Value: string);
begin
  FToAction := Value;
end;

procedure TDesignWFStep.SetStep(const Value: integer);
begin
  FStep := Value;
end;

procedure TDesignWFStep.SetstepKind(const Value: TWFStepKind);
begin
  FstepKind := Value;
end;

{$endregion}   // TDesignWorkFlow

initialization
  ProcessWorkFlow := TWorkflow.Create;

  // charger les entités
  ProcessWorkFlow.Entity.Add('Client=866000');
  ProcessWorkFlow.Entity.Add('Commerce=866994');
  ProcessWorkFlow.Entity.Add('Achats=867000');
  ProcessWorkFlow.Entity.Add('Finance=12345655');
  ProcessWorkFlow.Entity.Add('Informatique=56998422');

finalization
  ProcessworkFlow.Free;


end.
