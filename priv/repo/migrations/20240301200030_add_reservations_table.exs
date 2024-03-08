defmodule ReservationApp.Repo.Migrations.AddReservationsTable do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add(:date, :date, null: false)
      add(:user_id, :string)
      add(:user_slug, :string)

      timestamps()
    end

    create(unique_index(:reservations, [:date]))
  end
end
