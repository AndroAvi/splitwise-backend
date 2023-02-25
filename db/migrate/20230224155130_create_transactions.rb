class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.references :from, foreign_key: { to_table: :users }
      t.references :to, foreign_key: { to_table: :users }
      t.float :amount
      t.belongs_to :expense
      t.belongs_to :group
      t.timestamps
    end
  end
end
