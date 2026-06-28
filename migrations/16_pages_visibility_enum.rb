# frozen_string_literal: true

# Replace the concealed boolean with a visibility enum: concealed/public/crawlable.
Sequel.migration do
  up do
    extension :pg_enum
    create_enum(:page_visibility, %w(concealed public crawlable))

    add_column :pages, :visibility, :page_visibility, default: "public", null: false
    from(:pages).where(concealed: true).update(visibility: "concealed")

    drop_column :pages, :concealed
  end

  down do
    extension :pg_enum
    add_column :pages, :concealed, TrueClass
    from(:pages).where(visibility: "concealed").update(concealed: true)

    drop_column :pages, :visibility
    drop_enum(:page_visibility)
  end
end
