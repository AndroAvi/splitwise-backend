class CreateExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :expenses do |t|
      t.string  :title
      t.integer :category
      t.float :amount
      t.belongs_to :group
      t.references :paid_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
