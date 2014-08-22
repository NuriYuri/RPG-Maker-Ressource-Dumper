#===
#¤Lancement d'un jeu RGSS avec injection de script
#---
#Ouais, c'est codé en ruby parce qu'il fallait que je test très rapidement et maintenant j'ai tellement la flemme d'ouvrir VisualStudio 2012 pour faire un exe
#©20/08/2014 - Nuri Yuri (塗 ゆり) - Création du script
#©21/08/2014 - Nuri Yuri (塗 ゆり) - Nettoyage ajout de l'injection du script via un fichier script.rb
#===
#encoding: UTF-8
begin
  INI_File="Game.ini"
  INI_File2=".//#{INI_File}"
  STATIC_RGSS_PTR=0x10000000 #>Pointeur théorique du RGSS en mémoire, si vous avez des merdes dans vos système c'est autre chose.
  require "win32API"
  GetPrivateProfileString=Win32API.new("kernel32","GetPrivateProfileString","ppppip","i")
  MultiByteToWideChar=Win32API.new("kernel32","MultiByteToWideChar","iipipi","i")
  #===
  #>Création de la fenêtre
  #===
  wndclass=[0x0002|0x0001,
  Win32API.new("kernel32","GetProcAddress","ip","i").call(Win32API.new("kernel32","LoadLibrary","p","i").call("User32.dll"),"DefWindowProcA"),
  0,0,
  Win32API.new("kernel32","GetCurrentProcess","","i").call,
  0,0,0,0,"RGSS Player"].pack("IIIIIIIIIp")
  res=Win32API.new("user32","RegisterClass","p","i").call(wndclass)
  title="\x00"*256
  GetPrivateProfileString.call("Game","Title","",title,256,INI_File2)
  hwnd=Win32API.new("user32","CreateWindowEx","ippiiiiiiiii","i").call(0x00000100,"RGSS Player",title,0x80000000|0x00C00000|0x00010000|0x00020000|0x00080000,0,0,800,600,0,0,0,0)
  raise "Impossible de créer la fenêtre" if hwnd==0
  Win32API.new("user32","ShowWindow","ii","i").call(hwnd,5)
  #===
  #>Recherche de la DLL du RGSS
  #===
  dll_name="\x00"*256
  GetPrivateProfileString.call("Game","Library","",dll_name,256,INI_File2)
  dll_name.delete!("\x00")
  RGSS=File.expand_path(dll_name.size>0 ? dll_name : "RGSS104E.dll") #>expand_path pour que ça charge celle du dossier et pas celle du système.
  #===
  #>Identification du RGSS
  #===
  if(RGSS.include?("RGSS2"))
    multi_byte=true
    ext="2"
  elsif(RGSS.include?("RGSS3"))
    multi_byte=true
    ext="3"
  else
    multi_byte=false
    ext=""
  end
  #===
  #>Initialisation du RGSS
  #===
  RGSSInitialize=Win32API.new(RGSS,"RGSSInitialize#{ext}","i","i")
  Win32API.new(RGSS,"RGSSSetupRTP","ppi","i").call(File.expand_path(INI_File),"\x00"*1024,1024)
  RGSSInitialize.call(STATIC_RGSS_PTR)
  #===
  #>Chargement du script
  #===
  f=File.new("Script.rb","rb")
  script=f.read(f.size)
  f.close
  Win32API.new(RGSS,"RGSSEval","p","i").call(script)
  #===
  #>Lancement du RGSS
  #===
  scripts="\x00"*256
  GetPrivateProfileString.call("Game","Scripts","",scripts,256,INI_File2)
  if(multi_byte)
    sleep(1)
    GC.start
    scripts.force_encoding("UTF-8").delete!("\x00")
    scriptsm="\x00"*(2*scripts.size)
    sz=MultiByteToWideChar.call(65001,0,scripts,scripts.bytesize,scriptsm,scriptsm.bytesize)
    rgssad=File.expand_path("Game.rgss#{ext}a")
    rgssadm="\x00"*(2*rgssad.size)
    sz=MultiByteToWideChar.call(65001,0,rgssad,rgssad.bytesize,rgssadm,rgssadm.bytesize)
    sleep(0.5)
    Win32API.new(RGSS,"RGSSGameMain","ipp","i").call(hwnd,scriptsm,rgssadm)
  else
    Win32API.new(RGSS,"RGSSGameMain","ipp","i").call(hwnd,scripts,File.expand_path("Game.rgssad"))
  end
rescue Exception
  p $!,$!.message,$!.backtrace
  system("pause")
end