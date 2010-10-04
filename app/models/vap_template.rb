class VapTemplate < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'Operator'

  NAME_PREFIX = "vap"

  ENC_TYPES = %w(none wep psk psk2 wpa wpa2)
  ENC_TYPES_SELECT = { 'none'        => 'none', 
                       'WEP'         => 'wep', 
                       'WPA psk'     => 'psk', 
                       'WPA2 psk'    => 'psk2', 
                       'WPA 802.1x'  => 'wpa', 
                       'WPA2 802.1x' => 'wpa2' 
                     }
   ENC_TYPES_FSELECT = {  'none' => 'none', 
                          'wep'   => 'WEP', 
                          'psk'   => 'WPA psk', 
                          'psk2'   => 'WPA2 psk', 
                          'wpa'   => 'WPA 802.1x', 
                          'wpa2'  => 'WPA2 802.1x' 
                      }
  ENC_TYPES_WKEY = %w(wep psk psk2 wpa wpa2)
  ENC_TYPES_WRADIUS = %w(wpa wpa2)
  
  VISIBILITIES = %w(hidden broadcasted)
  VISIBILITIES_SELECT = { 'Hidden'      => 'hidden',
                          'Broadcasted' => 'broadcasted'
                        }
  VISIBILITIES_FSELECT = { 'hidden'      => 'Hidden',
                           'broadcasted' => 'Broadcasted'
                        }

  validates_presence_of :essid
  validates_inclusion_of :visibility, :in => VapTemplate::VISIBILITIES
  validates_inclusion_of :encryption, :in => VapTemplate::ENC_TYPES
  validates_presence_of :key, :if => :key_needed?
  validates_presence_of :radius_auth_server, :if => :radius_needed?
  validates_presence_of :radius_auth_server_port, :if => :radius_needed?

  belongs_to :bridge_template
  belongs_to :radio_template, :touch => true

  # Template instances
  has_many :vaps, :dependent => :destroy
  has_many :instances, :class_name => 'Vap', :foreign_key => :vap_template_id

  def key_needed?
    VapTemplate::ENC_TYPES_WKEY.include?(encryption)
  end

  def radius_needed?
    VapTemplate::ENC_TYPES_WRADIUS.include?(encryption)
  end

  # Update linked template instances
  after_create { |record|
    # We have a new vap_template
    record.radio_template.radios.each do |r|
      # For each linked template instance, create a new vap and associate it with
      # the corresponding access_point
      nv = r.vaps.build( :radio => r )
      nv.link_to_template( record )
      nv.save!
    end
  }

  after_save { |record|
    # Are we saving after a change of bridging status?
    if record.bridge_template_id_changed?
      # Vap changed bridging status/bridge
      record.instances.each do |v|
        # For each linked template instance, opportunely change its bridging status
        if record.bridge_template.nil?
          v.do_unbridge!
        else
          v.do_bridge!(v.radio.access_point.bridges.find(:first, :conditions => "bridge_template_id = #{record.bridge_template.id}"))
        end
      end
    end
  }

  def do_bridge!(b)
    self.bridge_template = b
    self.save!
  end

  def do_unbridge!
    self.bridge_template = nil
    self.save!
  end

  # Accessor methods (read)
  def name
     "r#{self.radio_template.id}v#{self.id}"
  end
  
  def friendly_name
     "essid '#{self.essid}' - radio '#{self.radio_template.name}'"
  end

end