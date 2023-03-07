program WorkflowManager;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  uWorkflow in 'uWorkflow.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
