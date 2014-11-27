module WeightBattle::Model
  class Acheivement < Sequel::Model
    plugin :timestamps, update_on_create: true
    unless table_exists?
      set_schema do
        Integer :id, unsigned: true, null: false, primary_key: true, auto_increment: true
        String :registrant, null: false, unique: true
        Float :acheivement, null: false
        Float :score, null: false
        Int :updown, null: false, default: 0
        timestamp :updated_at, null: false
        timestamp :created_at, null: false
      end
      create_table
    end
  end
end
