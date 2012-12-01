class CreateVisit < ActiveRecord::Migration
  def up
    create_table :visits do |t|
      t.string :ip, :country, :shortened_url_id
    end
  end

  def down
    drop_table :visits
  end
end