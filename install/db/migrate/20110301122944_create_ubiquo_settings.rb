class CreateUbiquoSettings < ActiveRecord::Migration
  def self.up
    uhook_create_ubiquo_settings_table do |t|
      t.string :key
      t.string :context
      t.string :type
      t.text :value, :null => true
      t.text :allowed_values
      t.text :options
      t.string :is_inherited

      t.timestamps

    end
  end

  def self.down
    drop_table :settings
  end
end
