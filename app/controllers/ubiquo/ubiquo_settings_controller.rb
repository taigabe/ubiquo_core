class Ubiquo::UbiquoSettingsController < UbiquoController

  Ubiquo::Extensions.load_extensions_for UbiquoController, self

  #ubiquo_config_call :setting_access_control, {:context => :ubiquo_setting}

  # GET /settings
  # GET /settings.xml
  # GET /settings.json
  def index

    find_settings
    respond_to do |format|
      format.html # index.html.erb
      format.xml  {
        render :xml => @contexts
      }
    end
  end

  def destroy
    @ubiquo_setting = UbiquoSetting.find(params[:id])
    if @ubiquo_setting.destroy
      flash[:notice] = t("ubiquo.ubiquo_setting.destroyed",
                        :key => @ubiquo_setting.key,
                        :context => @ubiquo_setting.context)
    else
      flash[:error] = t("ubiquo.ubiquo_setting.destroy_error")
    end
    respond_to do |format|
      format.html { redirect_to(ubiquo_ubiquo_settings_url) }
      format.xml  { head :ok }
    end
  end

  # POST /settings
  # POST /settings.xml
  def create
    result = @result = uhook_create_ubiquo_setting
    respond_to do |format|
      if result[:errors].present?
        flash[:error] = result[:errors].length == 1 ?
          "1 #{t("ubiquo.ubiquo_setting.error")}" :
          "#{result[:errors].length} #{t("ubiquo.ubiquo_setting.errors")}"
      end
      notice_message = nil
      if result[:valids].present?
        notice_message = result[:valids].length == 1 ?
          "1 #{t("ubiquo.ubiquo_setting.created")}" :
          "#{result[:valids].length} #{t("ubiquo.ubiquo_setting.createds")}"
      end

      if result[:errors].present?
        flash[:error] = [notice_message, flash[:error]].compact.join(' - ')
      else
        flash[:notice] = notice_message
      end

      if result[:valids].present?
        format.xml  { render :xml => @ubiquo_setting, :status => :created, :location => @ubiquo_setting }
      elsif result[:errors].present?
        format.xml  { render :xml => result[:errors], :status => :unprocessable_entity }
      end

      format.html {
        find_settings
        render :action => :index
      }
    end
    @result = nil
  end

  private

  def find_settings
    @contexts = Ubiquo::Settings.overridable? ? uhook_index : {}
  end

  def load_setting
    @ubiquo_setting = UbiquoSetting.find(params[:id])
  end
end
