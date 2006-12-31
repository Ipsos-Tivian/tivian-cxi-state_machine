class CreateStates < ActiveRecord::Migration
  def self.up
    create_table :states do |t|
      t.column :name,               :string, :limit => 50,    :null => false
      t.column :short_description,  :string, :limit => 100
      t.column :long_description,   :string, :limit => 1024,  :null => false
      t.column :type,               :string
    end
    add_index :states, [:name, :type], :unique => true, :name => 'unique_state_name'
  end
  
  def self.down
    drop_table :states
  end
end