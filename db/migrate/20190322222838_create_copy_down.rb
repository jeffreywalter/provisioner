class CreateCopyDown < ActiveRecord::Migration[5.0]
  def change
    create_table :copy_downs do |t|
      t.string :name
      t.string :company_id
      t.string :property_id
      t.string :rule_id
      t.timestamps
    end

    create_table :target_rules do |t|
      t.string :rule_id
      t.string :company_id
      t.string :property_id
      t.string :name
      t.belongs_to :copy_down, index: true
      t.timestamps
    end
  end
end
