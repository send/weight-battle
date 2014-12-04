module WeightBattle::Model
  class Acheivement < Sequel::Model
    plugin :timestamps, update_on_create: true
    plugin :validation_helpers
    unless table_exists?
      set_schema do
        Integer :id, unsigned: true, null: false, primary_key: true, auto_increment: true
        String :registrant, null: false, unique: true
        Float :acheivement, null: false
        Int :updown, null: false, default: 0
        timestamp :updated_at, null: false
        timestamp :created_at, null: false
      end
      create_table
    end

    def validate
      super
      validates_presence [:registrant, :acheivement, :updown]
      validates_unique :registrant
      validates_numeric :acheivement
      validates_includes [-1, 1], :updown
    end
  end
end
