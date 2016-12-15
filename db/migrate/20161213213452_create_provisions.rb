class CreateProvisions < ActiveRecord::Migration[5.0]
  def change
    create_table :provisions do |t|
      t.string :company_name
      t.string :company_id
      t.string :property_name
      t.timestamps
    end
  end
end
