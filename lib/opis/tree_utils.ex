defmodule Opis.TreeUtils do
  @type tree :: any()

  def put_call(calls, 0, call) do
    [call | calls]
  end

  def put_call([current_child | older_children], depth, call) do
    [Map.update!(current_child, :children, &put_call(&1, depth - 1, call)) | older_children]
  end

  def specify_return(tree, depth, value) do
    update_call(tree, depth, &%{&1 | return: value})
  end

  def update_call([current_child | older_children], 0, update_fn) do
    [update_fn.(current_child) | older_children]
  end

  def update_call([current_child | older_children], depth, update_fn) do
    [
      Map.update!(current_child, :children, &update_call(&1, depth - 1, update_fn))
      | older_children
    ]
  end

  # @doc """
  # Performs a post-order traversal of the tree, applying `reducer` to each node
  # """
  # @spec tree_reduce(tree, (tree -> [tree]), acc, (tree, acc -> acc)) :: acc when acc: any
  # def tree_reduce(tree, child_fun, acc, reducer) do
  #   children = child_fun.(tree)
  #   new_acc = do_tree_reduce(children, child_fun, acc, reducer)
  #   reducer.(tree, new_acc)
  # end

  # defp do_tree_reduce([], _child_fun, acc, _reducer) do
  #   acc
  # end

  # defp do_tree_reduce([child | rest], child_fun, acc, reducer) do
  #   do_tree_reduce(
  #     rest,
  #     child_fun,
  #     tree_reduce(child, child_fun, acc, reducer),
  #     reducer
  #   )
  # end

  @doc """
  Maps each node in the tree with `fun` in pre-order
  """
  @spec tree_map(tree, atom, (tree -> tree)) :: tree
  def tree_map(tree, child_key, mapper) do
    new_tree = mapper.(tree)

    children = Map.get(new_tree, child_key)

    %{new_tree | child_key => do_tree_map(children, child_key, mapper)}
  end

  defp do_tree_map([], _child_key, _mapper) do
    []
  end

  defp do_tree_map([h | t], child_key, mapper) do
    [tree_map(h, child_key, mapper) | do_tree_map(t, child_key, mapper)]
  end
end
