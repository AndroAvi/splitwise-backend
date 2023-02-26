class AddSimplifyToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :simplify, :boolean, default: false
  end
end
