class CreateGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :category, default: 0
      t.timestamps
    end

    create_table :user_groups do |t|
      t.belongs_to :user
      t.belongs_to :group
      t.boolean :owner, default: false
      t.index [:user_id, :group_id], unique: true
      t.timestamps
    end
  end
end
