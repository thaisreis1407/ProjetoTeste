unit UFuncoes;

interface

uses
  System.JSON, Vcl.Dialogs, Vcl.StdCtrls, FireDAC.Comp.Client, System.Classes,
  REST.Client, Vcl.Forms, IPPeerClient, System.SysUtils;

function IsValidCPF(pCPF: string): Boolean;
function BuscarCEP(Cep: string): TStringList;
function CaminhoExe: String;

implementation

function IsValidCPF(pCPF: string): Boolean;
var
  v: array [0 .. 1] of Word;
  cpf: array [0 .. 10] of Byte;
  I: Byte;

begin
  Result := False;

  { Verificando se tem 11 caracteres }
  { Conferindo se todos d�gitos s�o iguais }
  if ((pCPF = '00000000000') or (pCPF = '11111111111') or (pCPF = '22222222222')
    or (pCPF = '33333333333') or (pCPF = '44444444444') or
    (pCPF = '55555555555') or (pCPF = '66666666666') or (pCPF = '77777777777')
    or (pCPF = '88888888888') or (pCPF = '99999999999') or (length(pCPF) <> 11))
  then
  begin
    exit;
  end;

  try
    for I := 1 to 11 do
      cpf[I - 1] := StrToInt(pCPF[I]);
    // Nota: Calcula o primeiro d�gito de verifica��o.
    v[0] := 10 * cpf[0] + 9 * cpf[1] + 8 * cpf[2];
    v[0] := v[0] + 7 * cpf[3] + 6 * cpf[4] + 5 * cpf[5];
    v[0] := v[0] + 4 * cpf[6] + 3 * cpf[7] + 2 * cpf[8];
    v[0] := 11 - v[0] mod 11;

    if v[0] >= 10 then
      v[0] := 0;

    // Nota: Calcula o segundo d�gito de verifica��o.
    v[1] := 11 * cpf[0] + 10 * cpf[1] + 9 * cpf[2];
    v[1] := v[1] + 8 * cpf[3] + 7 * cpf[4] + 6 * cpf[5];
    v[1] := v[1] + 5 * cpf[6] + 4 * cpf[7] + 3 * cpf[8];
    v[1] := v[1] + 2 * v[0];
    v[1] := 11 - v[1] mod 11;

    if v[1] >= 10 then
      v[1] := 0;

    // Nota: Verdadeiro se os d�gitos de verifica��o s�o os esperados.
    Result := ((v[0] = cpf[9]) and (v[1] = cpf[10]));
  except
    on E: Exception do
      Result := False;
  end;
end;

function BuscarCEP(Cep: string): TStringList;
var
  ObjRetorno: TJSONObject;
  RESTClient1: TRESTClient;
  RESTRequest1: TRESTRequest;
  RESTResponse1: TRESTResponse;
  Endereco: TStringList;
begin
  Cep := StringReplace(Cep, '.', '', [rfReplaceAll]);
  Cep := StringReplace(Cep, '-', '', [rfReplaceAll]);

  if trim(Cep) = '' then
    exit(nil);

  RESTClient1 := TRESTClient.Create(nil);
  RESTRequest1 := TRESTRequest.Create(nil);
  RESTResponse1 := TRESTResponse.Create(nil);
  try
    RESTRequest1.Client := RESTClient1;
    RESTRequest1.Response := RESTResponse1;
    RESTClient1.BaseURL := 'https://viacep.com.br/ws/' + Cep + '/json/';
    try
      RESTRequest1.Execute;
    except
      exit(nil);
    end;

    ObjRetorno := nil;
    if (RESTResponse1.JSONValue is TJSONObject) then
      ObjRetorno := RESTResponse1.JSONValue as TJSONObject;

    if (ObjRetorno.GetValue('erro') <> nil) and (ObjRetorno.Values['erro'].Value = 'true') then
      exit(Nil);

    if Assigned(ObjRetorno) then
    begin
      // data := obj.Values['payload'] as TJSONObject;
      Endereco := TStringList.Create;

      Endereco.Add(ObjRetorno.Values['logradouro'].Value);
      Endereco.Add(ObjRetorno.Values['complemento'].Value);
      Endereco.Add(ObjRetorno.Values['bairro'].Value);
      Endereco.Add(ObjRetorno.Values['localidade'].Value);
      Endereco.Add(ObjRetorno.Values['uf'].Value);
    end;
  finally
    FreeAndNil(RESTClient1);
    FreeAndNil(RESTRequest1);
    FreeAndNil(RESTResponse1);
  end;
  Result := Endereco;
end;

function CaminhoExe: String;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

end.
