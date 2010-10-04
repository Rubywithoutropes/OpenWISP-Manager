class BridgeTemplatesController < ApplicationController
  layout nil

  before_filter :load_wisp
  before_filter :load_access_point_template
    
  access_control :subject_method => :current_operator do
    default :deny

    allow :admin
    allow :wisp_admin, :of => :wisp, :to => [ :index, :new, :edit, :create, :update, :destroy ]
    allow :wisp_operator, :of => :wisp, :to => [ :index, :new, :edit, :create, :update, :destroy ]
    allow :wisp_viewer, :of => :wisp, :to => [:index]
  end

  def load_wisp
    @wisp = Wisp.find(params[:wisp_id])
  end

  def load_access_point_template
    @access_point_template = @wisp.access_point_templates.find(params[:access_point_template_id])
  end

  # GET /wisps/:wisp_id/access_point_templates/:access_point_template_id/bridge_templates
  def index
    @bridge_templates = @access_point_template.bridge_templates.find(:all)
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /wisps/:wisp_id/access_point_templates/:access_point_template_id/bridge_templates/new
  def new
    @bridge_template  = @access_point_template.bridge_templates.build()

    # Present to the view only unbridged interface
    @tap_templates = @access_point_template.tap_templates.select { |t| 
      t.bridge_template.nil?
    }
    @ethernet_templates = @access_point_template.ethernet_templates.select { |v| 
      v.bridge_template.nil?
    }
    @vap_templates = @access_point_template.vap_templates.select { |v| 
      v.bridge_template.nil?
    }
    @vlan_templates = @access_point_template.vlan_templates.select { |v| 
      v.bridge_template.nil?
    }

    @selected_tap_templates = []
    @selected_ethernet_templates = []
    @selected_vap_templates = []
    @selected_vlan_templates = []

    @addressing_mode = "none"

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /bridge_templates/1/edit
  def edit
    @bridge_template  = @access_point_template.bridge_templates.find(params[:id])
    
    # Present to the view only unbridged interface or interface linked to this bridge
    @tap_templates = @access_point_template.tap_templates.select { |t| 
      t.bridge_template.nil? or t.bridge_template == @bridge_template
    }
    @ethernet_templates = @access_point_template.ethernet_templates.select { |e| 
      e.bridge_template.nil? or e.bridge_template == @bridge_template
    }
    @vap_templates = @access_point_template.vap_templates.select { |v| 
      v.bridge_template.nil? or v.bridge_template == @bridge_template
    }
    @vlan_templates = @access_point_template.vlan_templates.select { |v| 
      v.bridge_template.nil? or v.bridge_template == @bridge_template
    }    
    
    @selected_tap_templates = @bridge_template.tap_templates.map { |t| t.id }
    @selected_ethernet_templates = @bridge_template.ethernet_templates.map { |e| e.id }
    @selected_vap_templates = @bridge_template.vap_templates.map { |v| v.id }
    @selected_vlan_templates = @bridge_template.vlan_templates.map { |v| v.id }

    @addressing_mode = @bridge_template.addressing_mode
    # Addressing mode change is disabled if we have instances linked to this template... 
    @addressing_mode_disabled = (!@bridge_template.bridges.nil? and (@bridge_template.bridges.length > 0)) 
  end

  # POST /wisps/:wisp_id/access_point_templates/:access_point_template_id/bridge_templates
  def create
    @bridge_template = @access_point_template.bridge_templates.build(params[:bridge_template])

    # Present to the view only unbridged interface
    @tap_templates = @access_point_template.tap_templates.select { |t| 
      t.bridge_template.nil?
    }
    @ethernet_templates = @access_point_template.ethernet_templates.select { |e| 
      e.bridge_template.nil?
    }
    @vap_templates = @access_point_template.vap_templates.select { |v| 
      v.bridge_template.nil?
    }
    @vlan_templates = @access_point_template.vlan_templates.select { |v| 
      v.bridge_template.nil?
    }
    
    @selected_tap_templates = params[:tap_templates].nil? ? [] : params[:tap_templates].collect { |s| s.to_i }
    @bridge_template.tap_templates = @selected_tap_templates.map { |t|
      @access_point_template.tap_templates.find(t) 
    }

    @selected_ethernet_templates = params[:ethernet_templates].nil? ? [] : params[:ethernet_templates].collect { |s| s.to_i }
    @bridge_template.ethernet_templates = @selected_ethernet_templates.map { |e| 
      @access_point_template.ethernet_templates.find(e) 
    }

    @selected_vap_templates = params[:vap_templates].nil? ? [] : params[:vap_templates].collect { |s| s.to_i }
    @bridge_template.vap_templates = @selected_vap_templates.map { |v| 
      @access_point_template.vap_templates.find(v)
    }
    
    @selected_vlan_templates = params[:vlan_templates].nil? ? [] : params[:vlan_templates].collect { |s| s.to_i }
    @bridge_template.vlan_templates = @access_point_template.vlan_templates.select { |s|  
      @selected_vlan_templates.include?(s.id)
    }

    @addressing_mode = params[:bridge_template][:addressing_mode]

    respond_to do |format|
      if @bridge_template.save
        #flash[:notice] = 'Bridge was successfully created.'
        format.html { 
          redirect_to(wisp_access_point_template_bridge_templates_url(@wisp, @access_point_template))
        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /wisps/:wisp_id/access_point_templates/:access_point_template_id/bridge_templates/1
  def update
    @bridge_template = @access_point_template.bridge_templates.find(params[:id])

    @addressing_mode = params[:bridge_template][:addressing_mode]

    # Present to the view only unbridged interface or interface linked to this bridge
    @tap_templates = @access_point_template.tap_templates.select { |t| 
      t.bridge_template.nil? or t.bridge_template == @bridge_template
    }
    @ethernet_templates = @access_point_template.ethernet_templates.select { |e| 
      e.bridge_template.nil? or e.bridge_template == @bridge_template
    }
    @vap_templates = @access_point_template.vap_templates.select { |v| 
      v.bridge_template.nil? or v.bridge_template == @bridge_template
    }
    @vlan_templates = @access_point_template.vlan_templates.select { |v| 
      v.bridge_template.nil? or v.bridge_template == @bridge_template
    }

    @selected_tap_templates = params[:tap_templates].nil? ? [] : params[:tap_templates].collect { |s| s.to_i }
    @selected_ethernet_templates = params[:ethernet_templates].nil? ? [] : params[:ethernet_templates].collect { |s| s.to_i }
    @selected_vap_templates = params[:vap_templates].nil? ? [] : params[:vap_templates].collect { |s| s.to_i }
    @selected_vlan_templates = params[:vlan_templates].nil? ? [] : params[:vlan_templates].collect { |s| s.to_i }


    # Unbridge or bridge taps
    tap_templates = @selected_tap_templates.map { |t| 
      @access_point_template.tap_templates.find(t) 
    }
    (tap_templates - @bridge_template.tap_templates).each { |t|
      t.do_bridge!(@bridge_template)
    }
    (@bridge_template.tap_templates - tap_templates).each { |t|
      t.do_unbridge!
    }
    @bridge_template.tap_templates = tap_templates

    # Unbridge or bridge ethernets
    ethernet_templates = @selected_ethernet_templates.map { |e| 
      @access_point_template.ethernet_templates.find(e)
    }
    (ethernet_templates - @bridge_template.ethernet_templates).each { |e|
      e.do_bridge!(@bridge_template)
    }
    (@bridge_template.ethernet_templates - ethernet_templates).each { |e|
      e.do_unbridge!
    }
    @bridge_template.ethernet_templates = ethernet_templates

    # Unbridge or bridge vaps
    vap_templates = @selected_vap_templates.map { |v| 
      @access_point_template.vap_templates.find(v)
    }
    (vap_templates - @bridge_template.vap_templates).each { |v|
      v.do_bridge!(@bridge_template)
    }
    (@bridge_template.vap_templates - vap_templates).each { |v|
      v.do_unbridge!
    }
    @bridge_template.vap_templates = vap_templates

    # Unbridge or bridge vlans
    vlan_templates = @selected_vlan_templates.map { |v|
      # HACK: should be "find"... but we have a (non-activerecord) array :(
      @access_point_template.vlan_templates.detect { |i| i.id == v }
    }
    (vlan_templates - @bridge_template.vlan_templates).each { |v|
      v.do_bridge!(@bridge_template)
    }
    (@bridge_template.vlan_templates - vlan_templates).each { |v| 
      v.do_unbridge!
    }
    @bridge_template.vlan_templates = vlan_templates

    respond_to do |format|
      if @bridge_template.update_attributes(params[:bridge_template])
        #flash[:notice] = 'Bridge was successfully updated.'
        format.html { 
          redirect_to(wisp_access_point_template_bridge_templates_url(@wisp, @access_point_template))
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /wisps/:wisp_id/access_point_templates/:access_point_template_id/bridge_templates/1
  def destroy
    @bridge_template  = @access_point_template.bridge_templates.find(params[:id])
    # dependents => :nullify in bridge_template model will remove any reference to this bridge
    @bridge_template.destroy

    respond_to do |format|
      format.html { 
        redirect_to(wisp_access_point_template_bridge_templates_url(@wisp, @access_point_template))
      }
    end
  end
end