class CreateSettings < ActiveRecord::Migration
  def self.up
    uhook_create_settings_table do |t|
      t.string :key
      t.string :context
      t.string :type
      t.text :value, :null => true
      t.text :allowed_values
      t.text :options
      t.string :is_inherited

      t.timestamps

      t.index :context
    end
  end

  def self.down
    drop_table :settings
  end
end
