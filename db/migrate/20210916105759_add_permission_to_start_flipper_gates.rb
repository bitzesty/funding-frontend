class AddPermissionToStartFlipperGates < ActiveRecord::Migration[6.1]
  def up
    execute "insert into flipper_gates (id, feature_key, key, value, created_at, updated_at) Values((select max(id) from flipper_gates) + 1,'permission_to_start_enabled', 'boolean', false, now(), now());"
  end

  def down
    execute "delete from flipper_gates where feature_key = 'permission_to_start_enabled';"
  end
end
