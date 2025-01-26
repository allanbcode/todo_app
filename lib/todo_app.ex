defmodule Todo do
  use Agent

  # Start the Agent process
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # Add a new task to the list
  def add_task(description) do
    Agent.update(__MODULE__, fn tasks ->
      id = if tasks == [], do: 1, else: Enum.max_by(tasks, & &1.id).id + 1
      tasks ++ [%{id: id, description: description, completed: false}]
    end)
  end

  # List all tasks with their statuses
  def list_tasks do
    Agent.get(__MODULE__, fn tasks ->
      Enum.map(tasks, fn %{id: id, description: description, completed: completed} ->
        status = if completed, do: "[x]", else: "[ ]"
        "#{id}. #{status} #{description}"
      end)
    end)
  end

  # Mark a task as completed by its ID
  def complete_task(task_id) do
    Agent.update(__MODULE__, fn tasks ->
      Enum.map(tasks, fn task ->
        if task.id == task_id do
          %{task | completed: true}
        else
          task
        end
      end)
    end)
  end

  # Remove a task by its ID
  def remove_task(task_id) do
    Agent.update(__MODULE__, fn tasks ->
      Enum.reject(tasks, fn task -> task.id == task_id end)
    end)
  end

  # Save the current task list to a file
  def save_to_file(file_path) do
    tasks = Agent.get(__MODULE__, & &1)
    File.write!(file_path, :erlang.term_to_binary(tasks))
  end

  # Load a task list from a file
  def load_from_file(file_path) do
    if File.exists?(file_path) do
      tasks = file_path |> File.read!() |> :erlang.binary_to_term()
      Agent.update(__MODULE__, fn _ -> tasks end)
    else
      {:error, "File not found"}
    end
  end
end
