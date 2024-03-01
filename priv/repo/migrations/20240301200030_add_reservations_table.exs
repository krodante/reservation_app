defmodule ReservationApp.Repo.Migrations.AddReservationsTable do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add(:date, :date)
      add(:user_id, :string)
      add(:user_slug, :string)
    end
  end
end
