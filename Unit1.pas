unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComObj, ShellAPI, XPMan, ComCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    XPManifest1: TXPManifest;
    ListBox1: TListBox;
    Label1: TLabel;
    Button4: TButton;
    Button5: TButton;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button3Click(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Edit1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Edit1Change(Sender: TObject);
  protected
    procedure WMDropFiles (var Msg: TMessage); message wm_DropFiles;
  private
    procedure SaveRules;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  RuleNames,RulePaths:TStringList;
  ChangedRules:boolean;

implementation

{$R *.dfm}

procedure RemoveFromFirewall(const RuleName:string);
const
NET_FW_PROFILE2_DOMAIN=1;
NET_FW_PROFILE2_PRIVATE=2;
NET_FW_PROFILE2_PUBLIC=4;
var
Profile:integer;
Policy2:OleVariant;
RObject:OleVariant;
begin
Profile:=NET_FW_PROFILE2_PRIVATE or NET_FW_PROFILE2_PUBLIC or NET_FW_PROFILE2_DOMAIN;
Policy2:=CreateOleObject('HNetCfg.FwPolicy2');
RObject:=Policy2.Rules;
RObject.Remove(RuleName);
end;

procedure AddToFirewall(Const Caption, Executable: String;Direct:boolean);
const
NET_FW_PROFILE2_DOMAIN=1;
NET_FW_PROFILE2_PRIVATE=2;
NET_FW_PROFILE2_PUBLIC=4;

NET_FW_IP_PROTOCOL_TCP=6;
NET_FW_IP_PROTOCOL_UDP=17;
NET_FW_IP_PROTOCOL_ICMPv4=1;
NET_FW_IP_PROTOCOL_ICMPv6=58;

NET_FW_ACTION_ALLOW=1;
NET_FW_RULE_DIR_IN=1;
NET_FW_RULE_DIR_OUT=2;
NET_FW_ACTION_BLOCK=0;
var
fwPolicy2:OleVariant;
RulesObject:OleVariant;
Profile:integer;
NewRule:OleVariant;
begin
Profile:=NET_FW_PROFILE2_PRIVATE or NET_FW_PROFILE2_PUBLIC or NET_FW_PROFILE2_DOMAIN; //�������
fwPolicy2:=CreateOleObject('HNetCfg.FwPolicy2');
RulesObject:=fwPolicy2.Rules;
NewRule:=CreateOleObject('HNetCfg.FWRule');
NewRule.Name:=Caption;
NewRule.Description:=Caption;
NewRule.Applicationname:= Executable;
NewRule.Protocol:=NET_FW_IP_PROTOCOL_TCP; //���������
//NewRule.LocalPorts:=Port; ���� ����, dword
if Direct then
NewRule.Direction:=NET_FW_RULE_DIR_IN //OUT - ���������, IN - ��������
else NewRule.Direction:=NET_FW_RULE_DIR_OUT;
NewRule.Enabled:=true;
NewRule.Grouping:='CAI';
NewRule.Profiles:=Profile;
NewRule.Action:=NET_FW_ACTION_BLOCK; //NET_FW_ACTION_BLOCK - ���������, NET_FW_ACTION_ALLOW - ���������
RulesObject.Add(NewRule);
end;

function CutName(name:string):string;
begin
if length(name)>33 then result:=copy(name,1,30)+'...' else result:=name;
end;

function CutNameSB(name:string):string;
begin
result:=copy(name,1,length(name)-20);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
if OpenDialog1.Execute then
if pos(OpenDialog1.FileName,RulePaths.Text)=0 then begin
RuleNames.Add(ExtractFileName(OpenDialog1.FileName)+' '+DateToStr(Date)+' '+TimeToStr(Time));
RulePaths.Add(OpenDialog1.FileName);
AddToFirewall(RuleNames.Strings[RuleNames.Count-1],RulePaths.Strings[RulePaths.Count-1],true);
AddToFirewall(RuleNames.Strings[RuleNames.Count-1],RulePaths.Strings[RulePaths.Count-1],false);
ListBox1.Items.Add(CutName(RuleNames.Strings[RuleNames.Count-1])+^I+CutName(RulePaths.Strings[RulePaths.Count-1]));
StatusBar1.SimpleText:=' ������� ��� ���������� "'+ExtractFileName(OpenDialog1.FileName)+'" ������� �������';
ChangedRules:=true;
end else StatusBar1.SimpleText:=' ������� ��� ���������� "'+ExtractFileName(OpenDialog1.FileName)+'" ��� ����������';
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
if ListBox1.ItemIndex<>-1 then begin
RemoveFromFirewall(RuleNames.Strings[ListBox1.ItemIndex]);
RemoveFromFirewall(RuleNames.Strings[ListBox1.ItemIndex]);
StatusBar1.SimpleText:=' ������� ��� ���������� "'+CutNameSB(RuleNames.Strings[ListBox1.ItemIndex])+'" ������� �������';
RuleNames.Delete(ListBox1.ItemIndex);
RulePaths.Delete(ListBox1.ItemIndex);
ListBox1.Items.Delete(ListBox1.ItemIndex);
ChangedRules:=true;
end else StatusBar1.SimpleText:=' �������� �������';
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
ShellExecute(0,'open','WF.msc',nil,nil,SW_ShowNormal);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
Close;
end;

procedure TForm1.WMDropFiles(var Msg: TMessage);
var
i,c,amount,size:integer;
Filename:PChar; path:string;
begin
inherited;
Amount:=DragQueryFile(Msg.WParam, $FFFFFFFF, Filename, 255);
c:=0;
for i:=0 to Amount-1 do begin
size:=DragQueryFile(Msg.WParam, i, nil, 0) + 1;
Filename:=StrAlloc(size);
DragQueryFile(Msg.WParam, i, Filename, size);
Path:=StrPas(Filename);
StrDispose(Filename);
if (AnsiLowerCase(ExtractFileExt(path))='.dll') or (AnsiLowerCase(ExtractFileExt(path))='.exe') then if FileExists(path) then
if pos(Path,RulePaths.Text)=0 then begin
inc(c);
RuleNames.Add(ExtractFileName(Path)+' '+DateToStr(Date)+' '+TimeToStr(Time));
RulePaths.Add(Path);
AddToFirewall(RuleNames.Strings[RuleNames.Count-1],RulePaths.Strings[RulePaths.Count-1],true);
AddToFirewall(RuleNames.Strings[RuleNames.Count-1],RulePaths.Strings[RulePaths.Count-1],false);
ListBox1.Items.Add(CutName(RuleNames.Strings[RuleNames.Count-1])+^I+CutName(RulePaths.Strings[RulePaths.Count-1]));
end;
end;
DragFinish(Msg.WParam);
if c>0 then begin
StatusBar1.SimpleText:=' ������ ������� ������� : '+IntToStr(c);
ChangedRules:=true;
end;
if c=0 then StatusBar1.SimpleText:=' �� ������� ������� �������';
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
Application.MessageBox('���������� �������� � �������� 0.2'+#13#10+'https://github.com/r57zone'+#13#10+'���� ���������� ����������: 05.05.2015','� ���������...',0);
end;

procedure SendMessageToHandle(TRGWND:hwnd;MsgToHandle:string);
var
CDS: TCopyDataStruct;
begin
CDS.dwData:=0;
CDS.cbData:=(length(MsgToHandle)+1)*sizeof(char);
CDS.lpData:=PChar(MsgToHandle);
SendMessage(TRGWND,WM_COPYDATA,Integer(Application.Handle),Integer(@CDS));
end;

procedure TForm1.FormCreate(Sender: TObject);
var
Rules:TStringList; i:integer; WND:HWND;
begin
Application.Title:=Caption;
ChangedRules:=false;
DragAcceptFiles(Handle, True);
rules:=TStringList.Create;
RuleNames:=TStringList.Create;
RulePaths:=TStringList.Create;
if FileExists(ExtractFilePath(ParamStr(0))+'\rules.txt') then rules.LoadFromFile(ExtractFilePath(ParamStr(0))+'\rules.txt');

for i:=0 to Rules.Count-1 do
if pos('#',rules.Strings[i])>0 then begin
RuleNames.Add(copy(rules.Strings[i],1,pos('#',rules.Strings[i])-1));
RulePaths.Add(copy(rules.Strings[i],pos('#',rules.Strings[i])+1,length(rules.Strings[i])-pos('#',rules.Strings[i])));
ListBox1.Items.Add(CutName(RuleNames.Strings[i])+^I+CutName(RulePaths.Strings[i]));
end;

//��������� ������, �������� ParamStr(1)

if ParamCount>0 then
if (AnsiLowerCase(ExtractFileExt(ParamStr(1)))='.dll') or (AnsiLowerCase(ExtractFileExt(ParamStr(1)))='.exe') then begin
if pos(ParamStr(1),RulePaths.Text)=0 then begin
RuleNames.Add(ExtractFileName(ParamStr(1))+' '+DateToStr(Date)+' '+TimeToStr(Time));
RulePaths.Add(ParamStr(1));
AddToFirewall(RuleNames.Strings[RuleNames.Count-1],RulePaths.Strings[RulePaths.Count-1],true);
AddToFirewall(RuleNames.Strings[RuleNames.Count-1],RulePaths.Strings[RulePaths.Count-1],false);
ListBox1.Items.Add(CutName(RuleNames.Strings[RuleNames.Count-1])+^I+CutName(RulePaths.Strings[RulePaths.Count-1]));
StatusBar1.SimpleText:=' ������� ��� ���������� "'+ExtractFileName(ParamStr(1))+'" ������� �������';
ChangedRules:=true;
//Close;
end;
end else StatusBar1.SimpleText:=' �� ������� ������� ������� ��� ���������� "'+ExtractFileName(ParamStr(1))+'"';
rules.Free;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
if ChangedRules then SaveRules;
RuleNames.Free;
RulePaths.Free;
end;

procedure TForm1.ListBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if ListBox1.ItemIndex<>-1 then ListBox1.Hint:=RulePaths.Strings[ListBox1.ItemIndex];
end;

procedure TForm1.Button3Click(Sender: TObject);
var
i,c:integer;
begin
c:=0;
for i:=RulePaths.Count-1 downto 0 do
if not FileExists(RulePaths.Strings[i]) then begin
RemoveFromFirewall(RuleNames.Strings[i]);
RemoveFromFirewall(RuleNames.Strings[i]);
RuleNames.Delete(i);
RulePaths.Delete(i);
ListBox1.Items.Delete(i);
inc(c);
end;
if c<>0 then StatusBar1.SimpleText:=' ������� ������ ��� �������������� ���������� : '+IntToStr(c) else
StatusBar1.SimpleText:=' ������ ��� �������������� ���������� �� �������';
if c>0 then ChangedRules:=true;
end;

procedure TForm1.SaveRules;
var
i:integer; rules:TStringList;
begin
rules:=TStringList.Create;
for i:=0 to RuleNames.Count-1 do
if Trim(RuleNames.Strings[i])<>'' then rules.Add(RuleNames.Strings[i]+'#'+RulePaths.Strings[i]);
rules.SaveToFile(ExtractFilePath(ParamStr(0))+'\rules.txt');
rules.Free;
end;

procedure TForm1.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if Edit1.Text='�����...' then begin Edit1.Font.Color:=clBlack; Edit1.Clear; end;
end;

procedure TForm1.Edit1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if Edit1.Text='�����...' then begin Edit1.Font.Color:=clBlack; Edit1.Clear; end;
end;

procedure TForm1.Edit1Change(Sender: TObject);
var
i:integer;
begin
for i:=0 to RuleNames.Count-1 do
if pos(AnsiLowerCase(Edit1.Text),AnsiLowerCase(RuleNames.Strings[i]))>0 then ListBox1.Selected[i]:=true;
end;

end.
