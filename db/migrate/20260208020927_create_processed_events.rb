class CreateProcessedEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_events do |t|
      t.string :event_id, null: false
      t.string :event_type, null: false
      t.jsonb  :payload, null: false, default: {}

      t.timestamps
    end

    add_index :processed_events, :event_id, unique: true
  end
end
