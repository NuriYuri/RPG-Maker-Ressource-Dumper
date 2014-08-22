#===
#¤Script Injecté qui va faire le boulot :D
#---
#©21/08/2014 - Nuri Yuri (塗 ゆり) - Création du script
#===
#===
#>Comme vous pouvez le voir, en ruby on peut faire des choses vraiment dégueulasses
#===
class Array
  alias at []
  def [](v)
    #>Je redéfini la méthode à son origine
    Array.class_eval("alias [] at")
    $Yuri_is_an_anonymous_module.start_hacking
    return at(v)
  end
end
#===
#>Je vais créer un module anonyme pour éviter de parasiter un module du jeu, 
#je vous recommande de changer $Yuri_is_an_anonymous_module en ce que vous voulez au cas où les scripts se défendent... (faut aussi le faire dans script_after !!)
#Si ils peuvent :D
#===
$Yuri_is_an_anonymous_module = Module.new do
  Game_Extraction_Dir="YuriExtraction"
  Data_Dir="#{Game_Extraction_Dir}/Data"
  Graphics_Dir="#{Game_Extraction_Dir}/Graphics"
  Script_Dir="#{Data_Dir}/Scripts.clear_data"
  Script_After="script_after.rb"
  INI_File2=".//Game.ini"
  GetPrivateProfileString=Win32API.new("kernel32","GetPrivateProfileString","ppppip","i")
  Force_ScriptExtract=false
  
  C_White=Color.new(255,255,255)
  C_Red=Color.new(190,0,0)
  C_Green=Color.new(0,190,0)
  module_function
  #===
  #>Méthode principale
  #===
  def start_hacking
    init_display
    set_font(nil,64,Color.new(128,0,190,255))
    draw_text(0,0,640,64,"Yuri Game Extractor",1)
    set_font(nil,nil,C_White)
    Graphics.update
    @accu=2
    sh_check_for_dir
    sh_check_for_scripts
    sh_load_after
    @sprite.opacity=128 unless @sprite.disposed?
    #kill_display
  rescue Exception
    p $!,$!.message,$!.backtrace
    kill_display
  end
  #===
  #>Initialisation de l'affichage de cirque
  #===
  def init_display
    @sprite=Sprite.new
    @sprite.z=100000001
    @sprite.bitmap=Bitmap.new(640,480)
    @accu=0
  end
  #===
  #>Arrêt du fonctionnement
  #===
  def kill_display
    60.times do Graphics.update end
    Graphics.freeze
    unless @sprite.disposed?
      @sprite.bitmap.dispose unless @sprite.bitmap.disposed?
      @sprite.dispose
    end
    Graphics.transition(40)
  end
  #===
  #>Modification du font
  #===
  def set_font(name=nil,size=nil,color=nil)
    name=Font.default_name unless name
    size=Font.default_size unless size
    if(@sprite.disposed? or @sprite.bitmap.disposed?)
      init_display
    end
    @sprite.bitmap.font.name=name
    @sprite.bitmap.font.size=size
    @sprite.bitmap.font.color=color if color
  end
  #===
  #>dessin du texte
  #draw_text(str)
  #draw_text(str,align)
  #draw_text(y,str,align)
  #draw_text(x,y,str,align)
  #draw_text(x,y,w,h,str[,align])
  #===
  def draw_text(*args)
    if(@sprite.disposed? or @sprite.bitmap.disposed?)
      init_display
    end
    if(args.size<=2)
      if @accu>14
        @accu=0 
        @sprite.bitmap.clear
      end
      @sprite.bitmap.draw_text(0,@accu*32,640,32,*args)
      @accu+=1
    elsif(args.size==3)
      @sprite.bitmap.draw_text(0,args[0],640,32,args[1],args[2])
    elsif(args.size==4)
      @sprite.bitmap.draw_text(args[0],args[1],640,32,args[2],args[3])
    else
      @sprite.bitmap.draw_text(*args)
    end
  end
  #===
  #>On va vérifier la présence des dossier utils, correction si problème
  #===
  def sh_check_for_dir
    draw_text("Initialisation de l'environnement.")
    Graphics.update
    sh_check_dir(Game_Extraction_Dir)
    draw_text(Game_Extraction_Dir)
    Graphics.update
    sh_check_dir(Data_Dir)
    draw_text(Data_Dir)
    Graphics.update
    sh_check_dir(Graphics_Dir)
    draw_text(Graphics_Dir)
    Graphics.update
    sh_check_dir(Script_Dir)
    draw_text(Script_Dir)
    Graphics.update
  end
  #===
  #>Vérification de l'existance d'un dossier
  #===
  def sh_check_dir(name)
    if(File.exist?(name))
      unless File.directory?(name)
        File.rename(name,name+Time.new.strftime("_%d_%m_%Y_%H_%M_%S"))
        Dir.mkdir(name)
      end
    else
      Dir.mkdir(name)
    end
  end
  #===
  #>Vérification de l'existance d'un fichier
  #===
  def sh_check_file(name)
    if(File.exist?(name))
      if File.directory?(name)
        File.rename(name,name+Time.new.strftime("_%d_%m_%Y_%H_%M_%S"))
      end
    end
  end
  #===
  #>Vérification de l'état des scripts
  #===
  def sh_check_for_scripts
    #scripts="#{Game_Extraction_Dir}/Scripts.rxdata"
    scripts="\x00"*256
    GetPrivateProfileString.call("Game","Scripts","",scripts,256,INI_File2)
    scripts="#{Game_Extraction_Dir}/#{scripts}".gsub("\\","/").delete("\x00")
    if(File.exist?(scripts) and !Force_ScriptExtract)
      set_font(nil,nil,C_Red)
      draw_text("Scripts non extraits, supprimez #{scripts} pour")
      draw_text("permettre l'extraction des scripts.")
    else
      set_font(nil,nil,C_Green)
      draw_text("Extraction des scripts...")
      save_data($RGSS_SCRIPTS,scripts)
      clean_regexp=/[\\\/\*\?\"<>\|\:]/
      clean_str="_"
      Graphics.update
      t=Time.new
      $RGSS_SCRIPTS.each_index do |i|
        name=$RGSS_SCRIPTS[i][1].gsub(clean_regexp) do clean_str end
        script=Zlib::Inflate.inflate($RGSS_SCRIPTS[i][2])
        f=File.new(sprintf("%s/[%03d] %s.rb",Script_Dir,i,name),"wb")
        f.write(script)
        f.close
        if((Time.new-t)>1)
          Graphics.update
          t=Time.new
        end
      end
    end
    set_font(nil,nil,C_White)
  end
  #===
  #>Vérification de l'intégrité du chemin vers un fichier
  #===
  def sh_check_file_path(fn)
    fn.gsub!("\\","/")
    farr=fn.split("/")
    filename=farr.pop
    farr.delete("")
    str=Game_Extraction_Dir.clone
    farr.each do |i|
      str<<"/#{i}"
      sh_check_dir(str)
    end
    str<<"/#{filename}"
    sh_check_file(str)
    return str
  end  
  #===
  #>Extraction de data
  #===
  def extract_data(fn,data)
    return if File.exist?("#{Game_Extraction_Dir}/#{fn}")
    str=sh_check_file_path(fn)
    return if File.exist?(str) #>On est jamais trop prudent :p
    draw_text("Extraction de #{fn}")
    Graphics.update
    t=Time.new
    f=File.new(str,"wb")
    f.write(Marshal.dump(data))
    f.close
    Graphics.update if((Time.new-t)>1)
  end
  #===
  #>Extraction d'un bitmap (Dépendant du script de Zeus !)
  #===
  def extract_bitmap(fn,bmp)
    return if File.exist?("#{Game_Extraction_Dir}/#{fn}")
    Graphics.update
    str=sh_check_file_path(fn)
    str2=delect_shity_char(str)
    return if File.exist?(str2)
    return if File.exist?(str2+".bmp")
    return if File.exist?(str2+".png")
    draw_text("Extraction de #{fn}")
    Graphics.update
    bmp.export(str)
    File.new(str2,"wb").close if(str != str2)
    Graphics.update
  end
  #===
  #>Modification des fichiers à accent
  #===
  def delect_shity_char(str)
    str2=str.clone
    r=false
    r=true if str2.gsub!("à","a")
    r=true if str2.gsub!("é","e")
    r=true if str2.gsub!("è","e")
    r=true if str2.gsub!("ê","e")
    r=true if str2.gsub!("ë","e")
    r=true if str2.gsub!("î","i")
    r=true if str2.gsub!("ï","i")
    r=true if str2.gsub!("ù","u")
    r=true if str2.gsub!("ü","u")
    r=true if str2.gsub!("ç","c")
    return str2 if r
    return str
  end
  #===
  #>Chargement des extensions qu'il faut intégrer après le chargement du RGSS
  #===
  def sh_load_after
    f=File.new(Script_After,"rb")
    str=f.read(File.size(Script_After))
    f.close
    Object.class_eval(str)
  end
end