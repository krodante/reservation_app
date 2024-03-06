defmodule ReservationApp.LocksServer do
  use GenServer
  require Logger

  @name __MODULE__
  @ttl 5

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: @name)

  def init(_) do
    Logger.info("Creating ETS #{@name}")

    :ets.new(:locked_dates, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, "ETS Created"}
  end

  def insert(key, value) do
    expires = :erlang.system_time(:second) + @ttl
    GenServer.call(@name, {:insert, {key, value, expires}})
  end

  def remove(key) do
    GenServer.call(@name, {:delete, key})
  end

  def handle_call({:insert, data}, _ref, state) do
    :ets.insert_new(:locked_dates, data)
    {:reply, :ok, state}
  end

  def handle_call({:delete, date}, _ref, state) do
    :ets.delete(:locked_dates, date)
    {:reply, :ok, state}
  end

  def create_ets_bucket() do
    :ets.new(:locked_dates, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])
  end
end
