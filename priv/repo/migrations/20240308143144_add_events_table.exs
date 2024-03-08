defmodule ReservationApp.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:date, :date)
      add(:name, :string, null: false)
      add(:user_id, :string)
      add(:user_slug, :string)

      timestamps()
    end
  end
end
