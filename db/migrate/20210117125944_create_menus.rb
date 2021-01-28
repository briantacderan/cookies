class CreateMenus < ActiveRecord::Migration[6.1]
  def change
    create_table :menus do |t|
      t.string :season
      t.string :start
      t.string :end
      t.timestamps
    end
  end
end
