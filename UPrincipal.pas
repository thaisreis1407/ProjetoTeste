unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  System.IniFiles,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Data.DB,
  Datasnap.DBClient, Vcl.Buttons, Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc,
  IdSMTP, IdSSLOpenSSL, IdMessage, IdText, IdAttachmentFile,
  IdExplicitTLSClientServerBase;

type
  TfrmCadastroCliente = class(TForm)
    lblNome: TLabel;
    edtNome: TEdit;
    mskTelefone: TMaskEdit;
    lblCpf: TLabel;
    mskCPF: TMaskEdit;
    lblTelefone: TLabel;
    grpEndereco: TGroupBox;
    lblEndereco: TLabel;
    edtLogadouro: TEdit;
    mskCep: TMaskEdit;
    lblLogadouro: TLabel;
    edtNumero: TEdit;
    lblNumero: TLabel;
    lblComplemento: TLabel;
    edtComplemento: TEdit;
    lblBairro: TLabel;
    edtBairro: TEdit;
    lblCidade: TLabel;
    edtCidade: TEdit;
    lblEstado: TLabel;
    cmbEstado: TComboBox;
    btnEnviar: TButton;
    btnCancelar: TButton;
    lblEmail: TLabel;
    edtEmail: TEdit;
    mskCelular: TMaskEdit;
    lblCelular: TLabel;
    SpeedButton1: TSpeedButton;
    edtPais: TEdit;
    Label1: TLabel;
    lblRG: TLabel;
    edtRG: TEdit;
    procedure btnEnviarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    procedure GeraXml;
    procedure EnviarEmail;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCadastroCliente: TfrmCadastroCliente;

implementation

uses UFuncoes;

{$R *.dfm}

procedure TfrmCadastroCliente.btnEnviarClick(Sender: TObject);
var
  cpf: string;
  xmlNode: TXMLNode;
begin

  cpf := mskCPF.Text;
  cpf := StringReplace(cpf, '.', '', [rfReplaceAll]);
  cpf := StringReplace(cpf, '-', '', [rfReplaceAll]);

  if (trim(cpf) <> '') then
  begin
    if (not IsValidCPF(cpf)) then
    begin
      ShowMessage('O CPF n�o � v�lido.');
      exit;
    end;
  end;

  Try
    GeraXml;
    EnviarEmail;
    ShowMessage('Informa��es enviadas com sucesso!');
  except
    on E: exception do
    begin
      ShowMessage('N�o foi poss�vel enviar seu cadastro. Detalhe: ' +
        E.Message);
    end;

  End;

end;

procedure TfrmCadastroCliente.EnviarEmail;
var
  IniFile: TIniFile;
  Destinatario, Usuario, Senha, SMTP: String;
  Porta: Integer;
  Anexo: string;

  IdSSLIOHandlerSocket: TIdSSLIOHandlerSocketOpenSSL;
  IdSMTP: TIdSMTP;
  IdMessage: TIdMessage;
  IdText: TIdText;

begin
  if not FileExists(CaminhoExe + 'Config.ini') then
    raise exception.Create('Arquivo de configura��o "' + CaminhoExe +
      'Config.ini' + '", n�o encontrado');

  IniFile := TIniFile.Create(CaminhoExe + 'Config.ini');

  Destinatario := IniFile.ReadString('EMAIL', 'DESTINATARIO', 'testethaismoc@gmail.com');
  Usuario := IniFile.ReadString('EMAIL', 'USUARIO', 'testethaismoc@gmail.com');
  Senha := IniFile.ReadString('EMAIL', 'SENHA', 'TesteMoc');
  SMTP := IniFile.ReadString('EMAIL', 'SMTP', 'smtp.gmail.com');
  Porta := StrToIntDef(IniFile.ReadString('EMAIL', 'PORTA', '465'), 465);

  Destinatario := InputBox('Aten��o', 'Destinat�rio', Destinatario);
  if Trim(Destinatario) = '' then  
    raise Exception.Create('Destinat�rio n�o informado');

  IdSSLIOHandlerSocket := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
  IdSMTP := TIdSMTP.Create(Self);
  IdMessage := TIdMessage.Create(Self);

  try
  
    IdSSLIOHandlerSocket.SSLOptions.Method := sslvSSLv23;
    IdSSLIOHandlerSocket.SSLOptions.Mode := sslmClient;

    IdSMTP.IOHandler := IdSSLIOHandlerSocket;

    IdSMTP.UseTLS := utUseImplicitTLS;
    IdSMTP.AuthType := satDefault;
    IdSMTP.Port := Porta;
    IdSMTP.Host := SMTP;
    IdSMTP.Username := Usuario;
    IdSMTP.Password := Senha;

    // Configura��o da mensagem (TIdMessage)
    IdMessage.From.Address := Usuario;
    IdMessage.From.Name := Usuario;

    IdMessage.ReplyTo.EMailAddresses := IdMessage.From.Address;
    IdMessage.Recipients.Add.Text := Destinatario;
    IdMessage.Subject := 'Dados do Meu Cadastro';
    IdMessage.Encoding := meMIME;

    IdText := TIdText.Create(IdMessage.MessageParts);
    IdText.Body.Add('Segue meus dados: ');
    IdText.Body.Add('');
    IdText.Body.Add('Nome: ' + edtNome.Text);
    IdText.Body.Add('CPF: ' + mskCPF.Text);
    IdText.Body.Add('RG: ' + edtRG.Text);    
    IdText.Body.Add('Telefone: ' + mskTelefone.Text);
    IdText.Body.Add('Celular: ' + mskCelular.Text);
    IdText.Body.Add('e-mail: ' + edtEmail.Text);
    IdText.Body.Add('');
    IdText.Body.Add('Endere�o');
    IdText.Body.Add('');
    IdText.Body.Add('Cep: ' + mskCep.Text);
    IdText.Body.Add('Logradouro: ' + edtLogadouro.Text);
    IdText.Body.Add('N�mero: ' + edtNumero.Text);
    IdText.Body.Add('Complemento: ' + edtComplemento.Text);
    IdText.Body.Add('Bairro: ' + edtBairro.Text);
    IdText.Body.Add('Cidade: ' + edtCidade.Text);
    IdText.Body.Add('Estado: ' + cmbEstado.Text);
    IdText.Body.Add('Pa�s: ' + edtPais.Text);

    IdText.ContentType := 'text/plain; charset=iso-8859-1';

    Anexo := CaminhoExe + 'Temp\Cadastro.xml';
    if FileExists(Anexo) then
    begin
      TIdAttachmentFile.Create(IdMessage.MessageParts, Anexo);
    end;

    try
      IdSMTP.Connect;
      IdSMTP.Authenticate;
    except
      on E: exception do
        raise exception.Create('Erro na conex�o ou autentica��o: ' + E.Message);
    end;

    // Envio da mensagem
    try
      IdSMTP.Send(IdMessage);
    except
      On E: exception do
        raise exception.Create('Erro ao enviar cadastro: ' + E.Message);
    end;
  finally
    // desconecta do servidor
    IdSMTP.Disconnect;
    // libera��o da DLL
    UnLoadOpenSSLLibrary;
    // libera��o dos objetos da mem�ria
    FreeAndNil(IdMessage);
    FreeAndNil(IdSSLIOHandlerSocket);
    FreeAndNil(IdSMTP);
  end;

end;

procedure TfrmCadastroCliente.GeraXml;
var
  LDocument: IXMLDocument;
  LNodeElement, NodeCData, NodeText: IXMLNode;
begin
  LDocument := TXMLDocument.Create(nil);
  LDocument.Active := True;

  { Define document content. }
  LDocument.DocumentElement := LDocument.CreateNode('DadosCadastro',
    ntElement, '');

  LDocument.DocumentElement.Attributes['nome'] := edtNome.Text;

  LDocument.DocumentElement.AddChild('nome').Text := edtNome.Text;
  LDocument.DocumentElement.AddChild('CPF').Text := mskCPF.Text;
  LDocument.DocumentElement.AddChild('RG').Text := edtRG.Text;
  LDocument.DocumentElement.AddChild('telefone').Text := mskTelefone.Text;
  LDocument.DocumentElement.AddChild('celular').Text := mskCelular.Text;
  LDocument.DocumentElement.AddChild('email').Text := mskCelular.Text;

  LNodeElement := LDocument.DocumentElement.AddChild('endereco');
  LNodeElement.AddChild('CEP').Text := mskCep.Text;
  LNodeElement.AddChild('logradouro').Text := edtLogadouro.Text;
  LNodeElement.AddChild('numero').Text := edtNumero.Text;
  LNodeElement.AddChild('complemento').Text := edtComplemento.Text;
  LNodeElement.AddChild('bairro').Text := edtBairro.Text;
  LNodeElement.AddChild('cidade').Text := edtCidade.Text;
  LNodeElement.AddChild('uf').Text := cmbEstado.Text;
  LNodeElement.AddChild('pais').Text := edtPais.Text;

  try
    LDocument.SaveToFile(CaminhoExe + 'Temp\Cadastro.xml');
  except
    raise exception.Create('N�o foi poss�vel criar o arquivo ' + CaminhoExe +
      'Temp\Cadastro.xml, verifique suas permiss�es.');
  end;
end;

procedure TfrmCadastroCliente.SpeedButton1Click(Sender: TObject);
var
  Endereco: TStringList;
begin
  try
    Endereco := BuscarCEP(mskCep.Text);

    if Assigned(Endereco) then
    begin
      edtLogadouro.Text := Endereco[0];
      edtComplemento.Text := Endereco[1];
      edtBairro.Text := Endereco[2];
      edtCidade.Text := Endereco[3];
      cmbEstado.ItemIndex := cmbEstado.Items.IndexOf(Endereco[4])
    end
    else
      Application.MessageBox('N�o foi poss�vel consultar seu cep',
        'Aten��o', 0);

  finally
    FreeAndNil(Endereco);
  end;

end;

procedure TfrmCadastroCliente.btnCancelarClick(Sender: TObject);
begin
  close;
end;

end.
