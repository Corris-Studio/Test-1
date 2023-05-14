object Form1: TForm1
  Left = 699
  Top = 367
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = '*'
  ClientHeight = 149
  ClientWidth = 149
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 89
    Height = 13
    Caption = #1059#1075#1086#1083' '#1080#1089#1090#1086#1095#1085#1080#1082#1072' 1'
  end
  object Label2: TLabel
    Left = 8
    Top = 48
    Width = 130
    Height = 13
    Caption = #1059#1075#1086#1083' '#1084#1077#1078#1076#1091' '#1080#1089#1090#1086#1095#1085#1080#1082#1072#1084#1080
  end
  object Label3: TLabel
    Left = 8
    Top = 104
    Width = 89
    Height = 13
    Caption = #1059#1075#1086#1083' '#1080#1089#1090#1086#1095#1085#1080#1082#1072' 2'
  end
  object EditLightSource1: TEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 0
    Text = '0'
    OnChange = EditLightSource1Change
  end
  object EditAngleInBetween: TEdit
    Left = 8
    Top = 64
    Width = 121
    Height = 21
    TabOrder = 1
    Text = '180'
    OnChange = EditAngleInBetweenChange
  end
  object EditLightSource2: TEdit
    Left = 8
    Top = 120
    Width = 121
    Height = 21
    Color = cl3DLight
    ReadOnly = True
    TabOrder = 2
    Text = '0'
  end
end
