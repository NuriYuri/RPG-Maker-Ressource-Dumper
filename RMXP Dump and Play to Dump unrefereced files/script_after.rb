#===
#¤Script Injecté après chargement du RGSS
#---
#©21/08/2014 - Nuri Yuri (塗 ゆり) - Création du script
#©22/08/2014 - Nuri Yuri (塗 ゆり) - Ajout de la phase de recherche des ressources utilisés pour l'édition sous RMXP
#===
#===
#>Petit trick sympatique pour extraire le data au fur et à mesure
#===
class Object
  def load_data(filename)
    data=super(filename)
    $Yuri_is_an_anonymous_module.extract_data(filename,data)
    return data
  end
end
#===
#>Modification du comportement de la classe Bitmap
#===
# Bitmap export v 3.0 by Zeus81
class Bitmap
  alias initialize_sdkjkgjsdlncvkjshdfv initialize
  def initialize(*args)
    initialize_sdkjkgjsdlncvkjshdfv(*args)
    $Yuri_is_an_anonymous_module.extract_bitmap(args[0],self) if(args.size==1 and args[0].class==String)
  rescue Errno::ENOENT
    nil
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #>Partie du script de Zeus81
  RtlMoveMemory_pi = Win32API.new('kernel32', 'RtlMoveMemory', 'pii', 'i')
  RtlMoveMemory_ip = Win32API.new('kernel32', 'RtlMoveMemory', 'ipi', 'i')
  def address
    RtlMoveMemory_pi.call(a="\0"*4, __id__*2+16, 4)
    RtlMoveMemory_pi.call(a, a.unpack('L')[0]+8, 4)
    RtlMoveMemory_pi.call(a, a.unpack('L')[0]+16, 4)
    a.unpack('L')[0]
  end
  def export(filename)
    format=File.extname(filename)
    if(self.height>10_000 or self.width>10_000)
      filename<<".bmp" if(format.to_s.size==0)
      format='.bmp'
    end
    filename<<'.png' if(format.to_s.size==0)
    file = File.open(filename, 'wb')
    case format
    when '.bmp'
      data, size = String.new, width*height*4
      RtlMoveMemory_ip.call(data.__id__*2+8, [size,address].pack('L2'), 8)
      file.write(['BM',size+54,0,54,40,width,height,1,32,0,size,0,0,0,0].pack('a2L6S2L6'))
      file.write(data)
      RtlMoveMemory_ip.call(data.__id__*2+8, "\0"*8, 8)
    else
      def file.write_chunk(chunk)
        write([chunk.size-4].pack('N'))
        write(chunk)
        write([Zlib.crc32(chunk)].pack('N'))
      end
      file.write("\211PNG\r\n\32\n")
      file.write_chunk("IHDR#{[width,height,8,6,0,0,0].pack('N2C5')}")
      RtlMoveMemory_pi.call(data="\0"*(width*height*4), address, data.size)
      (width*height).times {|i| data[i<<=2,3] = data[i,3].reverse!}
      deflate, null_char, w4 = Zlib::Deflate.new(9), "\0", width*4
      (height-1).downto(0) {|i| deflate << null_char << data[i*w4,w4]}
      file.write_chunk("IDAT#{deflate.finish}")
      deflate.close
      file.write_chunk('IEND')
    end
    file.close
  end
end
#===
#>Extraction des ressources RMXP
#===
$RMXP_EXTRACTOR = Module.new do
  C_FullRed=Color.new(255,0,0)
  C_White=Color.new(255,255,255)
  module_function
  #===
  #>Démarrage de la séquence d'extraction
  #===
  def start
    $Yuri_is_an_anonymous_module.draw_text("Extraction des datas du jeu...")
    Graphics.update
    $data_actors = load_data("Data/Actors.rxdata") rescue nil
    $data_classes = load_data("Data/Classes.rxdata") rescue nil
    $data_skills  = load_data("Data/Skills.rxdata") rescue nil
    $data_items   = load_data("Data/Items.rxdata") rescue nil
    $data_weapons = load_data("Data/Weapons.rxdata") rescue nil
    $data_armors  = load_data("Data/Armors.rxdata") rescue nil
    $data_enemies = load_data("Data/Enemies.rxdata") rescue nil
    $data_troops  = load_data("Data/Troops.rxdata") rescue nil
    $data_states  = load_data("Data/States.rxdata") rescue nil
    $data_animations = load_data("Data/Animations.rxdata") rescue nil
    $data_tilesets = load_data("Data/Tilesets.rxdata") rescue nil
    $data_common_events = load_data("Data/CommonEvents.rxdata") rescue nil
    $data_system  = load_data("Data/System.rxdata") rescue nil
    $map_info = load_data("Data/MapInfos.rxdata") rescue nil
    Graphics.frame_rate=120
    Graphics.update
    extract_actors
    extract_icon_type_res($data_skills,RPG::Skill)
    extract_icon_type_res($data_items,RPG::Item)
    extract_icon_type_res($data_weapons,RPG::Weapon)
    extract_icon_type_res($data_armors,RPG::Armor)
    extract_enemies
    extract_animations
    extract_tilesets
    RPG::Cache.clear
    Graphics.update
    GC.start
    Graphics.update
    sleep(1)
    Graphics.update
    extract_maps
    extract_common_events
    Graphics.frame_rate=40
  end
  #===
  #>Affichage d'une erreur
  #===
  def error(str,no_font=false)
    $Yuri_is_an_anonymous_module.set_font(nil,nil,C_FullRed) unless no_font
    $Yuri_is_an_anonymous_module.draw_text(str)
    $Yuri_is_an_anonymous_module.set_font(nil,nil,C_White) unless no_font
  end
  #===
  #>Extraction des tilesets
  #===
  def extract_tilesets
    unless $data_tilesets
      error("Echec de l'extraction des tilesets.")
      return
    end
    error("Extration des Tilesets...",true)
    t=Time.new
    $data_tilesets.each do |i|
      next unless i and i.class==RPG::Tileset
      if(i.tileset_name and i.tileset_name.to_s.size>0)
        RPG::Cache.tileset(i.tileset_name) rescue nil
      end
      if(i.battleback_name and i.battleback_name.to_s.size>0)
        RPG::Cache.battleback(i.battleback_name) rescue nil
      end
      if(i.autotile_names.class==Array)
        i.autotile_names.each do |j|
          if(j and j.to_s.size>0)
            RPG::Cache.autotile(j) rescue nil
          end
        end
      end
      if((Time.new-t)>1)
        Graphics.update
        GC.start
        t=Time.new
      end
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Extraction des animations
  #===
  def extract_animations
    unless $data_animations
      error("Echec de l'extraction des animations.")
      return
    end
    error("Extration des Animations...",true)
    t=Time.new
    $data_animations.each do |i|
      next unless i and i.class==RPG::Animation
      if(i.animation_name and i.animation_name.to_s.size>0)
        RPG::Cache.animation(i.animation_name,0) rescue nil
      end
      if((Time.new-t)>1)
        Graphics.update
        GC.start
        t=Time.new
      end
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Extraction des ennemies
  #===
  def extract_enemies
    unless $data_enemies
      error("Echec de l'extraction des ennemis.")
      return
    end
    error("Extration des Ennemis...",true)
    t=Time.new
    $data_enemies.each do |i|
      next unless i and i.class==RPG::Enemy
      if(i.battler_name and i.battler_name.to_s.size>0)
        RPG::Cache.battler(i.battler_name,0) rescue nil
      end
      if((Time.new-t)>1)
        Graphics.update
        GC.start
        t=Time.new
      end
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Extraction des actors
  #===
  def extract_actors
    unless $data_actors
      error("Echec de l'extraction des Héros.")
      return
    end
    error("Extration des Héros...",true)
    t=Time.new
    $data_actors.each do |i|
      next unless i and i.class==RPG::Actor
      if(i.character_name and i.character_name.to_s.size>0)
        RPG::Cache.character(i.character_name,0) rescue nil
      end
      if(i.battler_name and i.battler_name.to_s.size>0)
        RPG::Cache.battler(i.battler_name,0) rescue nil
      end
      if((Time.new-t)>1)
        Graphics.update
        GC.start
        t=Time.new
      end
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Extraction des icones pour les skill/objets/armes/ect...
  #===
  def extract_icon_type_res(variable,_class)
    unless variable
      error("Echec de l'extraction des icones.")
      return
    end
    error("Extration des Icones (#{_class})...",true)
    t=Time.new
    variable.each do |i|
      next unless i and i.class==_class
      if(i.icon_name and i.icon_name.to_s.size>0)
        RPG::Cache.icon(i.icon_name) rescue nil
      end
      if((Time.new-t)>1)
        Graphics.update
        GC.start
        t=Time.new
      end
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Extraction des maps
  #===
  def extract_maps
    unless $map_info
      error("Echec de l'extraction des maps.")
      return
    end
    error("Extration des Maps...",true)
    t=Time.new
    $map_info.each_key do |map_id|
      map=load_data(sprintf("Data/MAP%03d.rxdata",map_id.to_i)) rescue nil
      next unless map
      map.events.each_value do |event|
        next unless event.class==RPG::Event
        event.pages.each do |page|
          next unless page.class==RPG::Event::Page
          next unless page.graphic.class==RPG::Event::Page::Graphic
          chara=page.graphic.character_name
          if(chara and chara.to_s.size>0)
            RPG::Cache.character(chara,0) rescue nil
          end
          scan_list(page.list)
          if(page.move_route and page.move_route.class==RPG::MoveRoute)
            scan_list(page.move_route.list)
          end
        end
        if((Time.new-t)>1)
          Graphics.update
          GC.start
          t=Time.new
        end
      end
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Extraction des évents communs
  #===
  def extract_common_events
    unless $data_common_events
      error("Echec de l'extraction des évents communs.")
      return
    end
    error("Extration des Events communs...",true)
    $data_common_events.each do |event|
      next unless event.class==RPG::CommonEvent
      scan_list(event.list) 
    end
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #===
  #>Scan des commandes d'évent
  #===
  def scan_list(list)
    t=Time.new
    list.each do |cmd|
      next unless cmd.class==RPG::EventCommand or cmd.class==RPG::MoveCommand
      param=cmd.parameters
      case cmd.code
      when 41 #>Changement de forme
        if(param[0].to_s.size>0)
          RPG::Cache.character(param[0],0) rescue nil
        end
      when 131 #>Changement de windowskin
        if(param[0].to_s.size>0)
          RPG::Cache.windowskin(param[0]) rescue nil
        end
      when 204 #>Changement des propriétés
        next if !param[1] or param[1].to_s.size==0
        case param[0]
        when 0 #>Panorama
          RPG::Cache.panorama(param[1],0) rescue nil
        when 1 #>Fog
          RPG::Cache.fog(param[1],0) rescue nil
        when 2 #>battleback
          RPG::Cache.battleback(param[1]) rescue nil
        end
      when 222 #>Transition
        if(param[0] and param[0].to_s.size>0)
          Bitmap.new("Graphics/Transitions/#{param[0]}").dispose rescue nil
        end
      when 231 #>Image en combat
        if(param[1] and param[1].to_s.size>0)
          RPG::Cache.picture(param[1]) rescue nil
        end
      when 322 #>Changement du graphique actor
        if(param[1].to_s.size>0)
          RPG::Cache.character(param[1],0) rescue nil
        end
        if(param[3].to_s.size>0)
          RPG::Cache.battler(param[3],0) rescue nil
        end
      when 209 #>Déplacements
        scan_list(param[1]) if param[1].class==Array
      end
      if((Time.new-t)>3)
        Graphics.update
        GC.start
        t=Time.new
      end
    end
  end
end
$RMXP_EXTRACTOR.start