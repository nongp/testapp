class AddOmiseIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :omise_id, :string
  end
end
