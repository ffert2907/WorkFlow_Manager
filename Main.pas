unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  uWorkflow, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageBin, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TForm1 = class(TForm)
    Button1: TButton;
    StaticText1: TStaticText;
    FDMemTable1: TFDMemTable;
    FDStanStorageBinLink1: TFDStanStorageBinLink;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Déclarations privées }
    FWFD : TDesignWorkFlow;
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


procedure TForm1.Button1Click(Sender: TObject);
begin
  FWFD.AddStep(TWFStepKind.wsInit, 0, 0, TWFOpp.wo_);
  FWFD.AddStep(TWFStepKind.wsAction, 1, 0, TWFOpp.wo_);
  FWFD.AddStep(TWFStepKind.wsAction, 1, 1, TWFOpp.woAND);
  FWFD.AddStep(TWFStepKind.wsTest, 2, 0, TWFOpp.wo_);
  FWFD.AddStep(TWFStepKind.wsInform, 3, 0, TWFOpp.wo_);
  FWFD.AddStep(TWFStepKind.wsFinal, 4, 0, TWFOpp.wo_);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  FWFD := TDesignWorkFlow.Create(self, uWorkflow.ProcessWorkFlow);
  FWFD.Align := TAlign.alLeft;
  FWFD.Width := 500;
end;

end.
